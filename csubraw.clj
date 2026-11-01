;; csubraw.clj -- Clojure port with persistent vectors (2026).
;;
;; Clojure's idiomatic data: an immutable vector of row vectors. There is
;; no in-place update, so each csub call builds a new out with assoc, one
;; element at a time, mirroring the element-by-element loop. The JVM's JIT
;; (as for Java and Kotlin) compiles the code; the question is how much the
;; boxed, persistent data structures cost. csubarr.clj is the same loop on
;; primitive Java double arrays.
;;
;;    clojure -M csubraw.clj 100 2000 10

(defn csub [ina nx ny out]
  (loop [iy 0 out out]
    (if (< iy ny)
      (let [inrow (nth ina iy)
            row (loop [ix 0 row (nth out iy)]
                  (if (< ix nx)
                    (recur (inc ix) (assoc row ix (+ (double (nth inrow ix)) ix iy)))
                    row))]
        (recur (inc iy) (assoc out iy row)))
      out)))

(let [[a b c] *command-line-args*
      nrpt (if a (Long/parseLong a) 100)
      nx (if b (Long/parseLong b) 2000)
      ny (if c (Long/parseLong c) 10)
      ina (vec (for [iy (range ny)] (vec (for [ix (range nx)] (double (- (+ nx ny) ix iy))))))
      out0 (vec (repeat ny (vec (repeat nx 0.0))))]
  (println "Arrays" nx "by" ny "count" nrpt)
  (let [out (loop [r 0 out out0] (if (< r nrpt) (recur (inc r) (csub ina nx ny out)) out))]
    (when-let [[ix iy] (first (for [iy (range ny) ix (range nx)
                                    :when (not= (get-in out [iy ix]) (+ (get-in ina [iy ix]) ix iy))]
                                [ix iy]))]
      (println "Error:" ix iy))))
