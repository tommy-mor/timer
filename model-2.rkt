#lang racket/base
(require racket/list
         db
         json)

;TODO write macro to automatically write json funciton for struct

; An app is a (app db)
; where db is an sqlite connection
(struct app (db))

; A user is a (user id name)
; where id is an integer, and name is a string
(struct user (userid name))
; takes a user and outputs its jsexpr representation
(define (user->jsexpr p)
   (hasheq 'name (user-name p)))

; A day is a (day dayid userid datestring)
; where dayid is an integer, userid is an integer, and datestring is a string
(struct day (dayid userid datestring))
; takes a day and outputs its jsexpr representation
(define (day->jsexpr p)
   (hasheq 'datestring (day-datestring p)))

; A timechunk is a (timechunk timechunkid dayid userid start end categoryid)
; where timechunkid is an integer, dayid is an integer, userid is an integer,
; start is a string, end is a string, and categoryid is an integer
(struct timechunk (timechunkid dayid userid start end categoryid))
; takes a timechunk and outputs its jsexpr representation
(define (timechunk->jsexpr t)
  (hasheq 'start (timechunk-start t)
          'end (timechunk-end t)))

; a category is a (category categoryid name color)
; where categoryid is an integer, name is a string, and color is a string
(struct category (categoryid name color))
; takes a category and outputs its jsexpr representation
(define (category->jsexpr t)
  (hasheq 'name (category-name t)
          'color (category-color t)))

;; TODO add data examples here
;; TODO add function tests

; initialize-app! : path? -> app?
; sets up app with database (if it does not exist already)
(define (initialize-app! home)
  (define db (sqlite3-connect #:database home #:mode 'create))
  (define the-app (app db))
  (unless (table-exists? db "users")
    (query-exec db "CREATE TABLE users (userid INTEGER PRIMARY KEY, username TEXT NOT NULL UNIQUE)")
    (app-insert-user! the-app "tommy")
    (app-insert-user! the-app "connor"))
  (unless (table-exists? db "days")
    (query-exec db
                (string-append
                 "CREATE TABLE days "
                 "(dayid INTEGER PRIMARY KEY, userid INTEGER, "
                 "date TEXT, "
                 "FOREIGN KEY (userid) REFERENCES users (userid))"))
    (user-insert-day! the-app (first (app-users the-app))
                      "2019-07-16 00:00:00.000")
    (user-insert-day! the-app (second (app-users the-app))
                      "2019-07-16 00:00:00.000"))

  (unless (table-exists? db "categories")
    (query-exec db
                (string-append
                 "CREATE TABLE categories "
                 "(categoryid INTEGER PRIMARY KEY, name TEXT NOT NULL, color TEXT NOT NULL)"))
    (app-insert-category! the-app "homework" "AB2567")
    (app-insert-category! the-app "gym" "0CAB99"))

  (unless (table-exists? db "timechunks")
    (query-exec db
                (string-append
                 "CREATE TABLE timechunks "
                 "(timechunkid INTEGER PRIMARY KEY, dayid INTEGER, "
                 "start TEXT, end TEXT, categoryid INTEGER, "
                 "FOREIGN KEY (categoryid) REFERENCES categories (categoryid), "
                 "FOREIGN KEY (dayid) REFERENCES days (dayid))"))
    (let* ([user (first (app-users the-app))]
           [day (first (user-days the-app user))]
           [category (first (app-categories the-app))]
           [other-category (second (app-categories the-app))])
      (day-insert-timechunk! the-app day "2019-07-16 00:00:00.000" "2019-07-16 10:30:00.000" category)
      (day-insert-timechunk! the-app day "2019-07-16 10:30:00.000" "2019-07-16 11:30:00.000" other-category)))
  the-app)

; app-users : app -> (listof user?)
; Queries the apps user ids and converts them into user structs
(define (app-users an-app)
  (define (vec->user uvec)
    (user (vector-ref uvec 0) (vector-ref uvec 1)))
  (map vec->user
       (query-rows
        (app-db an-app)
        "SELECT userid, username FROM users")))


; app-categories : app -> (listof category?)
; Queries the apps category ids converts them into category structs
(define (app-categories an-app)
  (define (vec->category cvec)
    (category (vector-ref cvec 0) (vector-ref cvec 1) (vector-ref cvec 2)))
  (map vec->category
       (query-rows
        (app-db an-app)
        "SELECT categoryid, name, color FROM categories")))

; app-insert-category! : app? string string -> void
; Consumes an app, a category name string and a color name string
; As a side-effect adds the given category to list of categories
(define (app-insert-category! an-app name color)
  (query-exec
   (app-db an-app)
   "INSERT INTO categories (name, color) VALUES (?, ?)"
   name color))

; app-insert-user! : app? string -> void
; Consumes an app and a user name string
; As a side-effect adds the given user to the table of users
(define (app-insert-user! an-app uname) 
  (query-exec
   (app-db an-app)
   "INSERT INTO users (username) VALUES (?)"
   uname))

; day-instert-category! : app? day string string category -> void
; Consumes an app, a day, two timestamp strings, and a category.
; As a side-effect adds timechunk to table with corresponding data
(define (day-insert-timechunk! an-app a-day starttime endtime a-category)
  (query-exec
   (app-db an-app)
   "INSERT INTO timechunks (dayid, start, end, categoryid) VALUES (?, ?, ?, ?)"
   (day-dayid a-day) starttime endtime (category-categoryid a-category)))

; user-insert-day! : app? user string -> void
; Consumes an app, a user, and a timestring
; As a side-effect adds the given day to the table of days
(define (user-insert-day! an-app user timestring)
  (query-exec
   (app-db an-app)
   "INSERT INTO days (userid, date) VALUES (?, ?)"
   (user-userid user) timestring))

; appusers : app user -> (listof day?)
; Queries the days for a given user and converts them to day structs
(define (user-days an-app user)
  (define (vec->day dvec)
    (day (vector-ref dvec 0) (vector-ref dvec 1) (vector-ref dvec 2)))
  (map vec->day
       (query-rows
        (app-db an-app)
        "SELECT dayid, userid, date FROM days WHERE userid = ?"
        (user-userid user))))

(provide initialize-app!
         user-days user-insert-day! day-insert-timechunk!
         app-users app-categories app-insert-user! app-insert-category!
         user-name
         category-name category-color
         user->jsexpr
         category->jsexpr)
