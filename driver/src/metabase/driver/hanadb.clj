(ns metabase.driver.hanadb
  "Minimal SAP HANA Metabase driver skeleton.

  This is intentionally a JDBC-first implementation. The goal of the first
  spike is to load the plugin, save a connection, run `SELECT 1 FROM DUMMY`,
  and perform a basic schema sync."
  (:require
   [clojure.java.jdbc :as jdbc]
   [metabase.driver :as driver]
   [metabase.driver.sql-jdbc.common :as sql-jdbc.common]
   [metabase.driver.sql-jdbc.connection :as sql-jdbc.conn]
   [metabase.driver.sql-jdbc.sync :as sql-jdbc.sync]))

(set! *warn-on-reflection* true)

(driver/register! :hanadb, :parent :sql-jdbc)

(doseq [[feature supported?] {:describe-default-expr   true
                              :describe-is-generated   true
                              :describe-is-nullable    true
                              :expression-literals     true
                              :identifiers-with-spaces true
                              :now                     true
                              :schemas                 true
                              :table-privileges        true}]
  (defmethod driver/database-supports? [:hanadb feature] [_driver _feature _db] supported?))

(defmethod driver/display-name :hanadb
  [_driver]
  "SAP HANA")

(defmethod driver/db-start-of-week :hanadb
  [_driver]
  :sunday)

(def ^:private database-type->base-type
  (sql-jdbc.sync/pattern-based-database-type->base-type
   [[#"(?i)^BIGINT$"                :type/BigInteger]
    [#"(?i)^INTEGER$"               :type/Integer]
    [#"(?i)^INT$"                   :type/Integer]
    [#"(?i)^SMALLINT$"              :type/Integer]
    [#"(?i)^TINYINT$"               :type/Integer]
    [#"(?i)^DECIMAL"                :type/Decimal]
    [#"(?i)^SMALLDECIMAL"           :type/Decimal]
    [#"(?i)^REAL$"                  :type/Float]
    [#"(?i)^DOUBLE$"                :type/Float]
    [#"(?i)^FLOAT$"                 :type/Float]
    [#"(?i)^BOOLEAN$"               :type/Boolean]
    [#"(?i)^DATE$"                  :type/Date]
    [#"(?i)^TIME$"                  :type/Time]
    [#"(?i)^SECONDDATE$"            :type/DateTime]
    [#"(?i)^TIMESTAMP$"             :type/DateTime]
    [#"(?i)^LONGDATE$"              :type/DateTime]
    [#"(?i)^VARCHAR"                :type/Text]
    [#"(?i)^NVARCHAR"               :type/Text]
    [#"(?i)^ALPHANUM"               :type/Text]
    [#"(?i)^SHORTTEXT"              :type/Text]
    [#"(?i)^CHAR"                   :type/Text]
    [#"(?i)^NCHAR"                  :type/Text]
    [#"(?i)^CLOB$"                  :type/Text]
    [#"(?i)^NCLOB$"                 :type/Text]
    [#"(?i)^TEXT$"                  :type/Text]
    [#"(?i)^BLOB$"                  :type/*]
    [#"(?i)^BINARY"                 :type/*]
    [#"(?i)^VARBINARY"              :type/*]
    [#"(?i)^ST_GEOMETRY"            :type/*]
    [#"(?i)^ST_POINT"               :type/*]]))

(defmethod sql-jdbc.sync/database-type->base-type :hanadb
  [_driver column-type]
  (database-type->base-type column-type))

(defmethod sql-jdbc.sync/excluded-schemas :hanadb
  [_driver]
  #{"SYS" "SYSTEM"})

(defmethod sql-jdbc.conn/connection-details->spec :hanadb
  [_driver {:keys [host port user password dbname db schema ssl]
            :or   {host "localhost"
                   port 30015}
            :as   details}]
  (let [base-options (cond-> {}
                       (seq (or dbname db)) (assoc :databaseName (or dbname db))
                       (seq schema)         (assoc :currentSchema schema)
                       ssl                  (assoc :encrypt true))
        base-subname (str "//" host ":" port "/"
                          (when (seq base-options)
                            (str "?" (sql-jdbc.common/additional-opts->string :url base-options))))]
    (-> {:classname   "com.sap.db.jdbc.Driver"
         :subprotocol "sap"
         :subname     base-subname
         :user        user
         :password    password}
        (sql-jdbc.common/handle-additional-options details)
        (merge (dissoc details :host :port :user :password :dbname :db :schema :ssl :additional-options)))))

(defmethod driver/can-connect? :hanadb
  [driver details]
  (sql-jdbc.conn/with-connection-spec-for-testing-connection [jdbc-spec [driver details]]
    (let [result (-> (jdbc/query jdbc-spec ["SELECT 1 FROM DUMMY"])
                     first
                     vals
                     first)]
      (= 1 (long result)))))
