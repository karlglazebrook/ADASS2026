;; csubraw-typed.lisp — typed Common Lisp variant.
;;
;; Same algorithm as csubraw.lisp, but with full type declarations.
;; This is the form that lets SBCL emit tight machine code: known
;; double-float types mean no boxed-number arithmetic, known
;; (simple-array double-float (* *)) means direct row-major indexing
;; without dispatch.

(declaim (optimize (speed 3) (safety 0) (debug 0) (space 0)))

(deftype matrix () '(simple-array double-float (* *)))

(declaim (ftype (function (matrix fixnum fixnum matrix) (values))
                subr))

(defun subr (in-arr nx ny out-arr)
   (declare (type matrix in-arr out-arr)
            (type fixnum nx ny))
   (dotimes (iy ny)
      (declare (type fixnum iy))
      (let ((fiy (coerce iy 'double-float)))
         (declare (type double-float fiy))
         (dotimes (ix nx)
            (declare (type fixnum ix))
            (setf (aref out-arr iy ix)
                  (+ (aref in-arr iy ix)
                     (coerce ix 'double-float)
                     fiy)))))
   (values))

(defun main ()
   (let* ((args (cdr sb-ext:*posix-argv*))
          (nrpt (if (>= (length args) 1) (parse-integer (nth 0 args)) 1000))
          (nx   (if (>= (length args) 2) (parse-integer (nth 1 args)) 2000))
          (ny   (if (>= (length args) 3) (parse-integer (nth 2 args)) 10))
          (in-arr  (make-array (list ny nx) :element-type 'double-float
                                            :initial-element 0d0))
          (out-arr (make-array (list ny nx) :element-type 'double-float
                                            :initial-element 0d0)))
      (declare (type matrix in-arr out-arr)
               (type fixnum nx ny nrpt))
      (dotimes (iy ny)
         (dotimes (ix nx)
            (setf (aref in-arr iy ix)
                  (coerce (- (+ nx ny) ix iy) 'double-float))))
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
