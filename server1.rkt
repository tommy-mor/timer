#lang racket
(require web-server/servlet
         web-server/dispatch
         json
         "model-2.rkt")

; TODO put index.html as template
; investigate stateless serverlets
; investigate continuations, call/cc
; do authentciation using cookies article on website
(define (response/json o)
  (response/output
   (λ (op)
     (write-json o op))
   #:mime-type #"application/json"))


(define-values (app-dispatch url)
  (let ([app (initialize-app!
              (build-path (current-directory)
                          "the-app-data.sqlite"))])
    (dispatch-rules
     [("users") (curry render-users-page app)] 
     [("categories") (curry render-categories-page app)])))

(define (render-users-page an-app request)
  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (user->jsexpr x)) (app-users an-app))))
  (send/suspend/dispatch response-generator))

(define (render-categories-page an-app request)
  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (category->jsexpr x)) (app-categories an-app))))
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
