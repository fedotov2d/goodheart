(ns validation)

(defn simple-validate [data]
  (and
   (< 0 (count (get data "name")))) ;; team name present
   (< 3 (count (get data "members")))) ;; team bigger than three members