#lang racket
(require web-server/servlet)
(provide/contract (start (request? . -> . response?)))

(require "model-2.rkt")


(define (start request)
  (render-app-page
   (initialize-app!
    (build-path (current-directory)
                "the-app-data.sqlite"))
   request))

(define (render-app-page an-app request)
  (define (response-generator embed/url)
    (response/xexpr
     `(html (head (title "My App"))
            (body (h1 "list")
                  ,(render-data (app-users an-app))))))
  (define (render-data users)
    `(ol ,@(map (lambda (x) `(li ,(user-name x))) users)))
  (send/suspend/dispatch response-generator))

(require web-server/servlet-env)
(serve/servlet start
               #:launch-browser? #f
               #:quit? #f
               #:listen-ip #f
               #:port 8000
               #:extra-files-paths
               (list (build-path (current-directory) "htdocs"))
               #:servlet-path
               "/server1.rkt")
