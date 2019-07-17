#lang racket/base
(require racket/list
         db)

; An app is a (app db)
; where db is an sqlite connection
(struct app (db))

; A user is a (user app id name)
; where app is an app, id is an integer, and name is a string
(struct user (app userid name))

; A day is a (day dayid userid datestring)
; where dayid is an integer, userid is an integer, and datestring is a string
(struct day (dayid userid datestring))

; A timechunk is a (timechunk timechunkid dayid userid start end categoryid)
; where timechunkid is an integer, dayid is an integer, userid is an integer,
; start is a string, end is a string, and categoryid is an integer
(struct timechunk (timechunkid dayid userid start end categoryid))

; a category is a (category categoryid name color)
; where categoryid is an integer, name is a string, and color is a string
(struct category (categoryid name color))

;; TODO add data examples here
;; TODO add function tests

; initialize-app! : path? -> app?
; sets up app with database (if it does not exist already)
(define (initialize-app! home)
  (define db (sqlite3-connect #:database home #:mode 'create))
  (define the-app (app db))
  (unless (table-exists? db "users")
    (query-exec db "CREATE TABLE users (userid INTEGER PRIMARY KEY, username TEXT NOT NULL UNIQUE)"))
  (unless (table-exists? db "days")
    (query-exec db
                (string-append
                 "CREATE TABLE days "
                 "(dayid INTEGER PRIMARY KEY, userid INTEGER, "
                 "date TEXT, "
                 "FOREIGN KEY (userid) REFERENCES users (userid))")))
  (unless (table-exists? db "timechunks")
    (query-exec db
                (string-append
                 "CREATE TABLE timechunks "
                 "(timechunkid INTEGER PRIMARY KEY, dayid INTEGER, "
                 "start TEXT, end TEXT, categoryid INTEGER, "
                 "FOREIGN KEY (categoryid) REFERENCES categories (categoryid), "
                 "FOREIGN KEY (dayid) REFERENCES days (dayid))")))
  (unless (table-exists? db "categories")
    (query-exec db
                (string-append
                 "CREATE TABLE categories "
                 "(categoryid INTEGER PRIMARY KEY, name TEXT NOT NULL, color TEXT NOT NULL)")))
  the-app)


(provide initialize-app!)
