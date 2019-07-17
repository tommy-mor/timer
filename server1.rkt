#lang racket
(require web-server/servlet)
(require web-server/dispatch)
;(provide/contract (start (request? . -> . response?)))

(require "model-2.rkt")

; TODO put index.html as template
; investigate stateless serverlets
; investigate continuations, call/cc
; do authentciation using cookies article on website

(define-values (app-dispatch url)
  (let ([app (initialize-app!
              (build-path (current-directory)
                          "the-app-data.sqlite"))])
    (dispatch-rules
     [("users") (curry render-users-page app)] 
     [("categories") (curry render-categories-page app)]
     )))

(define (render-users-page an-app request)
  (define (response-generator embed/url)
    (response/xexpr
     `(html (head (title "My App"))
            (body (h1 "list of users")
                  ,(render-data (app-users an-app))))))
  (define (render-data users)
    `(ol ,@(map (lambda (x) `(li ,(user-name x))) users)))
  (send/suspend/dispatch response-generator))

(define (render-categories-page an-app request)
  (define (response-generator embed/url)
    (response/xexpr
     `(html (head (title "My App"))
            (body (h1 "list of categories")
                  ,(render-data (app-categories an-app))))))
  (define (render-data categories)
    `(ol ,@(map (lambda (x)
                  `(li "name: " ,(category-name x)
                       ", color: " ,(category-color x))) categories)))
  (send/suspend/dispatch response-generator))

(require web-server/servlet-env)
(serve/servlet app-dispatch
               #:launch-browser? #f
               #:quit? #f
               #:listen-ip #f
               #:port 8000
               #:extra-files-paths
               (list (build-path (current-directory) "htdocs"))
               #:servlet-regexp #rx"")
