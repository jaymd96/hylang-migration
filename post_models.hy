;;; post_models.hy - SQLObject models for the posts system
;;; These models correspond to the tables created in migration 003

(import sqlobject [SQLObject StringCol IntCol DateTimeCol BoolCol 
                   ForeignKey SQLMultipleJoin SQLRelatedJoin UnicodeCol])
(import sqlobject.sqlbuilder [AND OR Select LEFTJOINOn])
(import datetime [datetime])
(import re)

;;; Post model - main blog post entity
(defclass Post [SQLObject]
  "Blog post model with relationships"
  
  ;; Table name
  (setv _table "posts")
  
  ;; Columns matching the migration
  (setv user (ForeignKey "User" :dbName "user_id" :notNone True))
  (setv title (StringCol :length 255 :notNone True))
  (setv slug (StringCol :length 255 :unique True :notNone True))
  (setv content (UnicodeCol :default None))  ; UnicodeCol for long text
  (setv excerpt (UnicodeCol :default None))
  (setv status (StringCol :length 20 :default "draft"))
  (setv published-at (DateTimeCol :dbName "published_at" :default None))
  (setv view-count (IntCol :dbName "view_count" :default 0))
  (setv created-at (DateTimeCol :dbName "created_at" :default datetime.now))
  (setv updated-at (DateTimeCol :dbName "updated_at" :default datetime.now))
  
  ;; Relationships
  (setv comments (SQLMultipleJoin "Comment" :joinColumn "post_id"))
  (setv tags (SQLRelatedJoin "Tag" 
                            :intermediateTable "post_tags"
                            :joinColumn "post_id"
                            :otherColumn "tag_id"))
  
  ;; Class methods for common queries
  (classmethod
    (defn get-published [cls &optional [limit None]]
      "Get published posts ordered by date"
      (setv query (cls.select 
                    (AND (= cls.q.status "published")
                         (!= cls.q.published-at None))
                    :orderBy "-published_at"))
      (if limit
        (list (take limit query))
        (list query))))
  
  (classmethod
    (defn get-by-slug [cls slug]
      "Find post by slug"
      (first (cls.selectBy :slug slug :limit 1))))
  
  (classmethod
    (defn get-drafts [cls user-id]
      "Get draft posts for a user"
      (list (cls.select 
              (AND (= cls.q.user-id user-id)
                   (= cls.q.status "draft"))
              :orderBy "-created_at"))))
  
  (classmethod
    (defn search [cls query-text]
      "Search posts by title or content"
      (list (cls.select
              (OR (.contains cls.q.title query-text)
                  (.contains cls.q.content query-text))))))
  
  ;; Instance methods
  (defn publish [self &optional [publish-time None]]
    "Publish the post"
    (setv self.status "published")
    (setv self.published-at (or publish-time (datetime.now)))
    (self.update-timestamp))
  
  (defn archive [self]
    "Archive the post"
    (setv self.status "archived")
    (self.update-timestamp))
  
  (defn increment-views [self]
    "Increment view counter"
    (setv self.view-count (+ self.view-count 1)))
  
  (defn update-timestamp [self]
    "Update the updated_at timestamp"
    (setv self.updated-at (datetime.now)))
  
  (defn add-tags [self tag-names]
    "Add tags to post by name"
    (for [tag-name tag-names]
      ;; Find or create tag
      (setv existing-tag (Tag.find-or-create tag-name))
      (when (not (in existing-tag (list self.tags)))
        (.add self.tags existing-tag))))
  
  (defn remove-all-tags [self]
    "Remove all tags from post"
    (for [tag (list self.tags)]
      (.remove self.tags tag)))
  
  (defn get-comment-count [self &optional [status "approved"]]
    "Get count of comments with specific status"
    (Comment.select
      (AND (= Comment.q.post-id self.id)
           (= Comment.q.status status))
      :count True))
  
  (defn get-approved-comments [self]
    "Get approved comments for this post"
    (list (Comment.select
            (AND (= Comment.q.post-id self.id)
                 (= Comment.q.status "approved"))
            :orderBy "created_at")))
  
  (defn generate-slug [self]
    "Generate slug from title"
    ;; Simple slug generation
    (-> self.title
        (.lower)
        (re.sub r"[^a-z0-9-]+" "-")
        (re.sub r"-+" "-")
        (.strip "-")))
  
  (defn to-dict [self]
    "Convert post to dictionary for JSON serialization"
    {:id self.id
     :title self.title
     :slug self.slug
     :excerpt self.excerpt
     :status self.status
     :published_at (if self.published-at 
                     (.isoformat self.published-at)
                     None)
     :view_count self.view-count
     :author {:id self.user.id
              :username self.user.username}
     :tags (list (map (fn [t] {:id t.id :name t.name}) 
                     self.tags))
     :comment_count (self.get-comment-count)
     :created_at (.isoformat self.created-at)
     :updated_at (.isoformat self.updated-at)}))

;;; Tag model - categorization for posts
(defclass Tag [SQLObject]
  "Tag model for categorizing posts"
  
  ;; Table name
  (setv _table "tags")
  
  ;; Columns
  (setv name (StringCol :length 50 :unique True :notNone True))
  (setv slug (StringCol :length 50 :unique True :notNone True))
  (setv description (UnicodeCol :default None))
  (setv created-at (DateTimeCol :dbName "created_at" :default datetime.now))
  
  ;; Relationships
  (setv posts (SQLRelatedJoin "Post"
                              :intermediateTable "post_tags"
                              :joinColumn "tag_id"
                              :otherColumn "post_id"))
  
  ;; Class methods
  (classmethod
    (defn find-or-create [cls name]
      "Find existing tag or create new one"
      (setv slug (cls.generate-slug name))
      (setv existing (first (cls.selectBy :slug slug :limit 1)))
      (if existing
        existing
        (cls :name name :slug slug))))
  
  (classmethod
    (defn get-popular [cls &optional [limit 10]]
      "Get most used tags"
      ;; This would need a raw SQL query to count post associations
      ;; For now, return all tags
      (list (take limit (cls.select :orderBy "name")))))
  
  (classmethod
    (defn generate-slug [cls name]
      "Generate slug from tag name"
      (-> name
          (.lower)
          (re.sub r"[^a-z0-9-]+" "-")
          (re.sub r"-+" "-")
          (.strip "-"))))
  
  ;; Instance methods
  (defn get-post-count [self]
    "Get number of posts with this tag"
    (len (list self.posts)))
  
  (defn get-published-posts [self]
    "Get published posts with this tag"
    (list (filter (fn [p] (= p.status "published"))
                  self.posts)))
  
  (defn merge-with [self other-tag]
    "Merge this tag with another, moving all posts"
    ;; Move all posts from other tag to this one
    (for [post (list other-tag.posts)]
      (when (not (in self (list post.tags)))
        (.add post.tags self))
      (.remove post.tags other-tag))
    ;; Delete the other tag
    (.destroySelf other-tag)))

;;; Comment model - user comments on posts
(defclass Comment [SQLObject]
  "Comment model for post discussions"
  
  ;; Table name
  (setv _table "comments")
  
  ;; Columns
  (setv post (ForeignKey "Post" :dbName "post_id" :notNone True))
  (setv user (ForeignKey "User" :dbName "user_id" :default None))
  (setv author-name (StringCol :dbName "author_name" :length 100 :default None))
  (setv author-email (StringCol :dbName "author_email" :length 255 :default None))
  (setv content (UnicodeCol :notNone True))
  (setv status (StringCol :length 20 :default "pending"))
  (setv created-at (DateTimeCol :dbName "created_at" :default datetime.now))
  
  ;; Class methods
  (classmethod
    (defn get-pending [cls &optional [limit None]]
      "Get comments awaiting moderation"
      (setv query (cls.select (= cls.q.status "pending")
                             :orderBy "created_at"))
      (if limit
        (list (take limit query))
        (list query))))
  
  (classmethod
    (defn get-recent-approved [cls &optional [limit 10]]
      "Get recently approved comments"
      (list (take limit 
                  (cls.select (= cls.q.status "approved")
                             :orderBy "-created_at")))))
  
  (classmethod
    (defn count-by-status [cls status]
      "Count comments with specific status"
      (cls.select (= cls.q.status status) :count True)))
  
  ;; Instance methods
  (defn approve [self]
    "Approve the comment"
    (setv self.status "approved"))
  
  (defn mark-spam [self]
    "Mark comment as spam"
    (setv self.status "spam"))
  
  (defn get-author-display-name [self]
    "Get display name for comment author"
    (if self.user
      self.user.username
      (or self.author-name "Anonymous")))
  
  (defn get-author-avatar [self]
    "Get avatar URL for comment author"
    (if self.user
      ;; Get from user profile if exists
      (if (and self.user.profile (first self.user.profile))
        (. (first self.user.profile) avatar-url)
        None)
      ;; Could generate gravatar from email
      None))
  
  (defn is-author [self user]
    "Check if user is the comment author"
    (and self.user
         user
         (= self.user.id user.id)))
  
  (defn can-edit [self user]
    "Check if user can edit this comment"
    (or (self.is-author user)
        ;; Add admin check here
        False))
  
  (defn to-dict [self]
    "Convert comment to dictionary"
    {:id self.id
     :post_id self.post.id
     :author {:name (self.get-author-display-name)
              :avatar (self.get-author-avatar)
              :is_registered (is-not self.user None)}
     :content self.content
     :status self.status
     :created_at (.isoformat self.created-at)}))

;;; Query helper functions
(defn get-posts-with-comments []
  "Get all posts that have comments"
  (list (Post.select 
          (Select (Comment.q.post-id 
                  :distinct True)))))

(defn get-posts-by-tag [tag-name]
  "Get all posts with a specific tag"
  (setv tag (first (Tag.selectBy :name tag-name :limit 1)))
  (if tag
    (list tag.posts)
    []))

(defn get-user-post-stats [user-id]
  "Get posting statistics for a user"
  {:total (Post.select (= Post.q.user-id user-id) :count True)
   :published (Post.select 
                (AND (= Post.q.user-id user-id)
                     (= Post.q.status "published"))
                :count True)
   :drafts (Post.select 
             (AND (= Post.q.user-id user-id)
                  (= Post.q.status "draft"))
             :count True)
   :comments (Comment.select
               (= Comment.q.user-id user-id)
               :count True)})

(defn bulk-update-post-status [post-ids new-status]
  "Update status for multiple posts"
  (for [post-id post-ids]
    (setv post (Post.get post-id))
    (when post
      (setv post.status new-status)
      (post.update-timestamp))))

;;; Validation functions
(defn validate-post-data [title content status]
  "Validate post data before saving"
  (setv errors [])
  
  (when (or (not title) (< (len title) 3))
    (.append errors "Title must be at least 3 characters"))
  
  (when (> (len title) 255)
    (.append errors "Title must be less than 255 characters"))
  
  (when (not (in status ["draft" "published" "archived"]))
    (.append errors "Invalid status"))
  
  (when (and (= status "published") (not content))
    (.append errors "Published posts must have content"))
  
  (if errors
    {:valid False :errors errors}
    {:valid True}))

;;; Example usage function
(defn example-post-usage []
  "Example of using the post models"
  (print "Creating a new post...")
  
  ;; Assume we have a user
  (setv user (first (User.select)))
  
  (when user
    ;; Create a post
    (setv post (Post :user user
                     :title "Introduction to Hylang"
                     :slug "introduction-to-hylang"
                     :content "Hylang is a Lisp that compiles to Python..."
                     :excerpt "Learn the basics of Hylang"
                     :status "draft"))
    
    (print f"Created post: {post.title}")
    
    ;; Add tags
    (post.add-tags ["hylang" "lisp" "python"])
    (print f"Added tags: {(list (map (fn [t] t.name) post.tags))}")
    
    ;; Publish the post
    (post.publish)
    (print f"Published at: {post.published-at}")
    
    ;; Add a comment
    (setv comment (Comment :post post
                          :user user
                          :content "Great article!"
                          :status "approved"))
    
    (print f"Added comment from: {(comment.get-author-display-name)}")
    
    ;; Get post data as dict
    (print "Post as dict:")
    (print (post.to-dict))))
