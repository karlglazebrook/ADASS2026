;; csubarrf32.clj -- csubarr.clj on Java float[][] (float32) arrays (2026).
;; Clojure has no float primitive arithmetic (everything is widened to double),
;; so each element is read as float, summed in double and narrowed on store.
(set! *warn-on-reflection* true)
(set! *unchecked-math* true)

(defn csub [^"[[F" ina ^long nx ^long ny ^"[[F" out]
  (dotimes [iy ny]
    (let [^floats inrow (aget ina iy)
          ^floats outrow (aget out iy)]
      (dotimes [ix nx]
        (aset outrow ix (float (+ (aget inrow ix) ix iy)))))))

(let [[a b c] *command-line-args*
      nrpt (if a (Long/parseLong a) 100)
      nx (if b (Long/parseLong b) 2000)
      ny (if c (Long/parseLong c) 10)
      ^"[[F" ina (make-array Float/TYPE ny nx)
      ^"[[F" out (make-array Float/TYPE ny nx)]
  (dotimes [iy ny]
    (dotimes [ix nx]
      (aset ^floats (aget ina iy) ix (float (- (+ nx ny) ix iy)))))
  (println "Arrays" nx "by" ny "count" nrpt)
  (dotimes [_ nrpt] (csub ina nx ny out))
  (when-let [[ix iy] (first (for [iy (range ny) ix (range nx)
                                  :when (not= (aget ^floats (aget out iy) ix)
                                              (float (+ (aget ^floats (aget ina iy) ix) ix iy)))]
                              [ix iy]))]
    (println "Error:" ix iy)))
