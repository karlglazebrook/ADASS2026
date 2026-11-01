;; csubraw.ss -- Scheme port for Chez Scheme (2026).
;;
;; A vector of rows, each an flvector (unboxed doubles), with the float-
;; specific operations fl+ and fixnum->flonum: Scheme written for speed, the
;; analogue of SBCL with type declarations (csubraw-typed.lisp). Chez
;; compiles each top-level form to native code as it loads. Run.py runs it
;; at the default optimize-level and at 3, which drops the run-time type
;; and bounds checks:
;;    scheme --script csubraw.ss 100 2000 10
;;    scheme --optimize-level 3 --script csubraw.ss 100 2000 10

(define (csub ina nx ny out)
  (do ((iy 0 (fx+ iy 1))) ((fx= iy ny))
    (let ((inrow (vector-ref ina iy)) (outrow (vector-ref out iy)))
      (do ((ix 0 (fx+ ix 1))) ((fx= ix nx))
        (flvector-set! outrow ix
          (fl+ (flvector-ref inrow ix) (fixnum->flonum (fx+ ix iy))))))))

(define args (command-line-arguments))
(define (arg k default) (if (> (length args) k) (string->number (list-ref args k)) default))
(define nrpt (arg 0 100))
(define nx (arg 1 2000))
(define ny (arg 2 10))
(define ina (make-vector ny))
(define out (make-vector ny))
(do ((iy 0 (+ iy 1))) ((= iy ny))
  (let ((row (make-flvector nx 0.0)))
    (do ((ix 0 (+ ix 1))) ((= ix nx))
      (flvector-set! row ix (fixnum->flonum (- (+ nx ny) ix iy))))
    (vector-set! ina iy row)
    (vector-set! out iy (make-flvector nx 0.0))))
(printf "Arrays ~a by ~a count ~a\n" nx ny nrpt)
(do ((r 0 (+ r 1))) ((= r nrpt)) (csub ina nx ny out))
(call/cc
  (lambda (done)
    (do ((iy 0 (+ iy 1))) ((= iy ny))
      (do ((ix 0 (+ ix 1))) ((= ix nx))
        (unless (= (flvector-ref (vector-ref out iy) ix)
                   (+ (flvector-ref (vector-ref ina iy) ix) ix iy))
          (printf "Error: ~a ~a\n" ix iy)
          (done #f))))))
