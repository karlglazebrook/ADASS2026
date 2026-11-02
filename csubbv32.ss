;; csubbv32.ss -- Scheme (Chez) float32 variant: each row is a bytevector of
;; IEEE single floats, read and written with bytevector-ieee-single-native-ref/set!.
;; Chez has no flvector of singles; the arithmetic is still in double (Scheme
;; flonums), with a widen on load and a narrow on store, as in OCaml's float32
;; Bigarray.  Storage is half that of csubraw.ss.
(define (csub ina nx ny out)
  (do ((iy 0 (fx+ iy 1))) ((fx= iy ny))
    (let ((inrow (vector-ref ina iy)) (outrow (vector-ref out iy)) (fiy (fixnum->flonum iy)))
      (do ((ix 0 (fx+ ix 1)) (k 0 (fx+ k 4))) ((fx= ix nx))
        (bytevector-ieee-single-native-set! outrow k
          (fl+ (bytevector-ieee-single-native-ref inrow k) (fixnum->flonum ix) fiy))))))

(define args (command-line-arguments))
(define (arg k default) (if (> (length args) k) (string->number (list-ref args k)) default))
(define nrpt (arg 0 100))
(define nx (arg 1 2000))
(define ny (arg 2 10))
(define ina (make-vector ny))
(define out (make-vector ny))
(do ((iy 0 (+ iy 1))) ((= iy ny))
  (let ((row (make-bytevector (* 4 nx) 0)))
    (do ((ix 0 (+ ix 1))) ((= ix nx))
      (bytevector-ieee-single-native-set! row (* 4 ix) (fixnum->flonum (- (+ nx ny) ix iy))))
    (vector-set! ina iy row)
    (vector-set! out iy (make-bytevector (* 4 nx) 0))))
(printf "Arrays ~a by ~a count ~a\n" nx ny nrpt)
(do ((r 0 (+ r 1))) ((= r nrpt)) (csub ina nx ny out))
(call/cc
  (lambda (done)
    (do ((iy 0 (+ iy 1))) ((= iy ny))
      (do ((ix 0 (+ ix 1))) ((= ix nx))
        (unless (= (bytevector-ieee-single-native-ref (vector-ref out iy) (* 4 ix))
                   (+ (bytevector-ieee-single-native-ref (vector-ref ina iy) (* 4 ix)) ix iy))
          (printf "Error: ~a ~a\n" ix iy)
          (done #f))))))
