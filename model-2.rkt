#lang racket/base
(require racket/list
         db)

;; An app is a (app db)
;; where db is an sqlite connection
(struct app (db))

;; A user is a (user app id name)
;; where app is an app, id is an integer, and name is a string
(struct user (app userid name))

;; A day is a (day dayid userid datestring)
;; where dayid is an integer, userid is an integer, and datestring is a string
(struct day (dayid userid datestring))

;; A timechunk is a (timechunk timechunkid dayid userid start end categoryid)
;; where timechunkid is an integer, dayid is an integer, userid is an integer,
;; start is a string, end is a string, and categoryid is an integer
(struct timechunk (timechunkid dayid userid start end categoryid))

;; a category is a (category categoryid name color)
;; where categoryid is an integer, name is a string, and color is a string
(struct category (categoryid name color))
