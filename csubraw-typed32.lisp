;; csubraw-typed32.lisp — typed Common Lisp variant, single-float (float32).  (ChatGPT review: precision twin of csubraw-typed.lisp, same 2D aref kernel.)
;;
;; Same algorithm as csubraw.lisp, but with full type declarations.
;; This is the form that lets SBCL emit tight machine code: known
;; single-float types mean no boxed-number arithmetic, known
;; (simple-array single-float (* *)) means direct row-major indexing
;; without dispatch.

(declaim (optimize (speed 3) (safety 0) (debug 0) (space 0)))

(deftype matrix () '(simple-array single-float (* *)))

(declaim (ftype (function (matrix fixnum fixnum matrix) (values))
                subr))

(defun subr (in-arr nx ny out-arr)
   (declare (type matrix in-arr out-arr)
            (type fixnum nx ny))
   (dotimes (iy ny)
      (declare (type fixnum iy))
      (let ((fiy (coerce iy 'single-float)))
         (declare (type single-float fiy))
         (dotimes (ix nx)
            (declare (type fixnum ix))
            (setf (aref out-arr iy ix)
                  (+ (aref in-arr iy ix)
                     (coerce ix 'single-float)
                     fiy)))))
   (values))

(defun main ()
   (let* ((args (cdr sb-ext:*posix-argv*))
          (nrpt (if (>= (length args) 1) (parse-integer (nth 0 args)) 1000))
          (nx   (if (>= (length args) 2) (parse-integer (nth 1 args)) 2000))
          (ny   (if (>= (length args) 3) (parse-integer (nth 2 args)) 10))
          (in-arr  (make-array (list ny nx) :element-type 'single-float
                                            :initial-element 0f0))
          (out-arr (make-array (list ny nx) :element-type 'single-float
                                            :initial-element 0f0)))
      (declare (type matrix in-arr out-arr)
               (type fixnum nx ny nrpt))
      (dotimes (iy ny)
         (dotimes (ix nx)
            (setf (aref in-arr iy ix)
                  (coerce (- (+ nx ny) ix iy) 'single-float))))
      (format t "Arrays ~A by ~A count ~A~%" nx ny nrpt)
      (dotimes (r nrpt)
         (subr in-arr nx ny out-arr))
      (block check
         (dotimes (iy ny)
            (dotimes (ix nx)
               (let ((got (aref out-arr iy ix))
                     (want (+ (aref in-arr iy ix) ix iy)))
                  (unless (= got want)
                     (format t "Error: ~A ~A ~A ~A~%"
                             got ix iy (aref in-arr iy ix))
                     (return-from check))))))))

(main)
