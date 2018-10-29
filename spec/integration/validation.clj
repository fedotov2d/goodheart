(ns validation)

;; simple case with true/false result
(defn simple-validate [data]
  (and
   (< 0 (count (get data "name")))) ;; team name present
   (< 3 (count (get data "members")))) ;; team bigger than three members

;; advanced case with error messages
(def validations
  [{:message "Team name should be present"
    :check (fn [data] (< 0 (count (get data "name"))))}
   {:message "Team should be greater than three members"
    :check (fn [data] (< 3 (count (get data "members"))))}])

(defn advanced-validate [data]
  (remove nil?
   (map
    (fn [validation]
      (when-not ((get validation :check) data) (get validation :message)))
    validations)))