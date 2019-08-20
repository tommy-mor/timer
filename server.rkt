#lang racket
(require web-server/servlet
         web-server/dispatch
         web-server/templates
         json
         "model-2.rkt")

; TODO put index.html as template
; investigate stateless serverlets
; investigate continuations, call/cc
; do authentciation using cookies article on website
(define (response/json o)
  (response/output
   (lambda (op)
     (write-json o op))
   #:mime-type #"application/json"))

(define (response/template username day)
  (response/full
   200 #"Okay"
   (current-seconds) TEXT/HTML-MIME-TYPE
   empty
   (list (string->bytes/utf-8 (include-template "templates/timeview.html")))))

(define-values (app-dispatch url)
  (let ([app (initialize-app!
              (build-path (current-directory)
                          "the-app-data.sqlite"))])
    (dispatch-rules
     [("v" (string-arg) (string-arg)) (curry render-template app)]
     [("users") (curry render-users-json app)] 
     [("category" "add") #:method "post" (curry add-category app)] 
     [("category" "remove" (integer-arg)) #:method "delete" (curry remove-category app)] 
     [("categories") (curry render-categories-json app)]
     [("day" (string-arg) (string-arg)) (curry render-timechunks-json app)]
     [("timechunk" "add") #:method "post" (curry add-timechunk app)]
     [("timechunk" "update") #:method "post" (curry update-timechunk app)]
     [("timechunk" "remove" (integer-arg)) #:method "delete" (curry remove-timechunk app)])))

(define (render-template an-app request username day)
  (app-insert-user! an-app username)
  (define (response-generator embed/url)
    (response/template username day))
  (send/suspend/dispatch response-generator))

(define (render-users-json an-app request)
  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (user->jsexpr x)) (app-users an-app))))
  (send/suspend/dispatch response-generator))

;; todo make this a route, so that goint go this url is persistent
(define (render-timechunks-json an-app request username datestring)
  (define a-user (app-user an-app username))
  (user-insert-day! an-app a-user datestring) ; insert day, database wont duplicate
  (define a-day (user-day an-app a-user datestring))

  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (timechunk->jsexpr x))
          (day-timechunks an-app a-day a-user))))
  (send/suspend/dispatch response-generator))

; request, string -> string
; takes request and binding name and returns binding string value
(define (extract-binding-string req name)
  (bytes->string/utf-8
   (binding:form-value
    (bindings-assq
     (string->bytes/utf-8 name) (request-bindings/raw req)))))

(define (add-category an-app request)
  (let* ([name (extract-binding-string request "name")]
         [color (extract-binding-string request "color")]
         [pk (app-insert-category! an-app name color)])
    (define (response-generator embed/url)
      (response/json
       pk))
    (send/suspend/dispatch response-generator)))

(define (remove-category an-app request pk)
  ;;(app-insert-category! an-app name color)
  (app-remove-category! an-app pk)
  (define (response-generator embed/url)
    (response/json
     "ok"))
  (send/suspend/dispatch response-generator))

(define (add-timechunk an-app request)
  (let* ([username (extract-binding-string request "username")]
         [start (extract-binding-string request "start")]
         [end (extract-binding-string request "end")]
         [datestring (extract-binding-string request "daystring")]
         [categoryid (extract-binding-string request "categoryid")]
         [a-user (app-user an-app username)]
         [a-day (user-day an-app a-user datestring)]
         [pk (day-insert-timechunk! an-app a-user a-day start end categoryid)])
    (define (response-generator embed/url)
      (response/json
       pk))
    (send/suspend/dispatch response-generator)))

(define (update-timechunk an-app request)
  (let* ([timechunkid (extract-binding-string request "timechunkid")]
         [start (extract-binding-string request "start")]
         [end (extract-binding-string request "end")]
         [pk (day-update-timechunk! an-app timechunkid start end)])
    (define (response-generator embed/url)
      (response/json
       pk))
    (send/suspend/dispatch response-generator)))

(define (remove-timechunk an-app request timechunkid)
  (day-remove-timechunk! an-app timechunkid)
  (define (response-generator embed/url)
    (response/json
     "ok"))
  (send/suspend/dispatch response-generator))

(define (render-categories-json an-app request)
  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (category->jsexpr x)) (app-categories an-app))))
  (send/suspend/dispatch response-generator))

(require web-server/servlet-env)
(serve/servlet app-dispatch
               #:launch-browser? #f
               #:quit? #f
               #:listen-ip #f
               #:port 8001
               #:extra-files-paths
               (list (build-path (current-directory) "htdocs"))
               #:servlet-regexp #rx"")
