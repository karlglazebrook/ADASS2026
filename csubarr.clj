;; csubarr.clj -- Clojure port on primitive Java double arrays (2026).
;;
;; The csubraw.clj loop, but the arrays are a Java double[][] mutated in
;; place with aget/aset, with type hints so the JIT sees unboxed doubles and
;; longs: Clojure written the way you would for speed.
;;
;;    clojure -M csubarr.clj 100 2000 10

(set! *warn-on-reflection* true)

(defn csub [^"[[D" ina ^long nx ^long ny ^"[[D" out]
  (dotimes [iy ny]
    (let [^doubles inrow (aget ina iy)
          ^doubles outrow (aget out iy)]
      (dotimes [ix nx]
        (aset outrow ix (+ (aget inrow ix) (double (+ ix iy))))))))

(let [[a b c] *command-line-args*
      nrpt (if a (Long/parseLong a) 100)
      nx (if b (Long/parseLong b) 2000)
      ny (if c (Long/parseLong c) 10)
      ^"[[D" ina (make-array Double/TYPE ny nx)
      ^"[[D" out (make-array Double/TYPE ny nx)]
  (dotimes [iy ny]
    (dotimes [ix nx]
      (aset ^doubles (aget ina iy) ix (double (- (+ nx ny) ix iy)))))
  (println "Arrays" nx "by" ny "count" nrpt)
  (dotimes [_ nrpt] (csub ina nx ny out))
  (when-let [[ix iy] (first (for [iy (range ny) ix (range nx)
                                  :when (not= (aget ^doubles (aget out iy) ix)
                                              (+ (aget ^doubles (aget ina iy) ix) ix iy))]
                              [ix iy]))]
    (println "Error:" ix iy)))
