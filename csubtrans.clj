;; csubtrans.clj -- Clojure persistent vectors built through transients (2026).
;;
;; csubraw.clj's immutable data, written the way a Clojure programmer builds a
;; vector element by element: transient, assoc!, persistent!. The result is the
;; same persistent vector of row vectors; only the construction is batched.
;;
;;    clojure -M csubtrans.clj 100 2000 10

(set! *unchecked-math* true)

(defn csub [ina ^long nx ^long ny out]
  (loop [iy 0 tout (transient out)]
    (if (< iy ny)
      (let [inrow (nth ina iy)
            row (loop [ix 0 trow (transient (nth out iy))]
                  (if (< ix nx)
                    (recur (inc ix) (assoc! trow ix (+ (double (nth inrow ix)) ix iy)))
                    (persistent! trow)))]
        (recur (inc iy) (assoc! tout iy row)))
      (persistent! tout))))

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
