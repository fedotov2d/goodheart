(ns validation)

(defn validate [data]
  (< 0 (count (get data "name"))))