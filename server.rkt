#lang racket
(require web-server/servlet
         web-server/dispatch
         web-server/templates
         json
         "model.rkt")

; response/json : jsexpr -> response
; Takes in any jsexpr and produces an http response for use with send/suspend/dispatch
(define (response/json o)
  (response/output
   (lambda (op)
     (write-json o op))
   #:mime-type #"application/json"))

; response/templtae : string string -> response
; Takes in a username string, and a day string, and produces an http response
; for use with send/suspend/dispatch
(define (response/template username daystring)
  (response/full
   200 #"Okay"
   (current-seconds) TEXT/HTML-MIME-TYPE
   empty
   (list (string->bytes/utf-8 (include-template "templates/timeview.html")))))

; defines app-dispatch and url as the two outputs of the
; dispatch-rules function, app-dispatch satisfying (-> request? any) (for use in serve/servelet),
; url satisfying contract (-> procedure? any/c ... string?) (not used)
(define-values (app-dispatch url)
  (let ([app (initialize-app!
              (build-path (current-directory)
                          "the-app-data.sqlite"))])
    (dispatch-rules
     [("v" (string-arg) (string-arg)) (curry render-template app)]
     [("users") (curry render-users-json app)] 
     [("category" "add") #:method "post" (curry add-category app)] 
     [("category" "remove" (integer-arg)) #:method "delete" (curry remove-category app)] 
     [("categories" (string-arg)) (curry render-categories-json app)]
     [("day" (string-arg) (string-arg)) (curry render-timechunks-json app)]
     [("timechunk" "add") #:method "post" (curry add-timechunk app)]
     [("timechunk" "update") #:method "post" (curry update-timechunk app)]
     [("timechunk" "remove" (integer-arg)) #:method "delete" (curry remove-timechunk app)])))

; render-template : app request string string -> response
; takes in an app, the request, and a username and produces an http response
(define (render-template an-app request username daystring)
  (app-insert-user! an-app username)
  (define (response-generator embed/url)
    (response/template username daystring))
  (send/suspend/dispatch response-generator))

; render-users json : app request -> response
; takes in an app and a request, and returns the json (from model) to the http request
(define (render-users-json an-app request)
  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (user->jsexpr x)) (app-users an-app))))
  (send/suspend/dispatch response-generator))

; render-timechunks-json : app request string string -> response
; takes in an app, a request, a username string, and a datestring, and returns all the
; timechunks in json associated with those data, as an http request
(define (render-timechunks-json an-app request username datestring)
  (define a-user (app-user an-app username))
  (user-insert-day! an-app a-user datestring) ; insert day, database wont duplicate
  (define a-day (user-day an-app a-user datestring))

  (define (response-generator embed/url)
    (response/json
     (map (lambda (x) (timechunk->jsexpr x))
          (day-timechunks an-app a-day a-user))))
  (send/suspend/dispatch response-generator))

; request string -> string
; takes request and binding name and returns binding string value from http form
(define (extract-binding-string req name)
  (bytes->string/utf-8
   (binding:form-value
    (bindings-assq
     (string->bytes/utf-8 name) (request-bindings/raw req)))))

; add-category : app request -> response
; takes in an app and a request (with a couple fields in the request),
; and adds the category to the database with the given form data. Then
; returns the database primary key of the data added as an http response
(define (add-category an-app request)
  (let* ([name (extract-binding-string request "name")]
         [color (extract-binding-string request "color")]
         [username (extract-binding-string request "username")]
         [a-user (app-user an-app username)]
         [pk (app-insert-category! an-app name color a-user)])
    (define (response-generator embed/url)
      (response/json
       pk))
    (send/suspend/dispatch response-generator)))

; remove-category : app request integer -> response
; takes in an app, a request, and an integer id value
; and removes the category to the database with the given data. Then
; returns an "ok" string as an http response
(define (remove-category an-app request pk)
  ;;(app-insert-category! an-app name color)
  (app-remove-category! an-app pk)
  (define (response-generator embed/url)
    (response/json
     "ok"))
  (send/suspend/dispatch response-generator))

; add-timechunk : app request -> response
; takes in an app and a request (with a few fields in the request),
; and adds the timechunk to the database with the given form data. Then
; returns the database primary key of the data added as an http response
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

; update-timechunk : app request -> response
; takes in an app and a request (with a few fields in the request),
; and updates the timechunk in the database with the given form data. Then
; returns the database primary key of the data added as an http response
(define (update-timechunk an-app request)
  (let* ([timechunkid (extract-binding-string request "timechunkid")]
         [start (extract-binding-string request "start")]
         [end (extract-binding-string request "end")]
         [pk (day-update-timechunk! an-app timechunkid start end)])
    (define (response-generator embed/url)
      (response/json
       pk))
    (send/suspend/dispatch response-generator)))

; remove-timechunk : app request integer -> response
; takes in an app, a request, and an integer primary key
; and removes the timechunk to the database with the given primary key.
; then returns an "ok" as an http response
(define (remove-timechunk an-app request timechunkid)
  (day-remove-timechunk! an-app timechunkid)
  (define (response-generator embed/url)
    (response/json
     "ok"))
  (send/suspend/dispatch response-generator))

; render-categories-json : app request string -> response
; takes in an app, a request, and an string username
; and returns a json http request with all of the categories for the given username
(define (render-categories-json an-app request username)
  (let ([a-user (app-user an-app username)])
    (define (response-generator embed/url)
      (response/json
       (map (lambda (x) (category->jsexpr x)) (app-categories an-app a-user))))
    (send/suspend/dispatch response-generator)))

(require web-server/servlet-env)
(serve/servlet app-dispatch
               #:launch-browser? #f
               #:quit? #f
               #:listen-ip #f
               #:port 8001
               #:extra-files-paths
               (list (build-path (current-directory) "htdocs"))
               #:servlet-regexp #rx"")
