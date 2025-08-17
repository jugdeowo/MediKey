;; MediKey - Medical Records Management Smart Contract
;; A decentralized medical records and patient data management system

;; Constants
(define-constant chief-medical-officer tx-sender)
(define-constant err-cmo-only (err u100))
(define-constant err-record-not-found (err u101))
(define-constant err-insufficient-clearance (err u102))
(define-constant err-invalid-data-size (err u103))
(define-constant err-record-duplicate (err u104))
(define-constant err-unauthorized-access (err u105))

;; Data Variables
(define-data-var total-records uint u0)
(define-data-var system-maintenance bool false)

;; Data Maps
(define-map medical-records
  { record-id: uint }
  {
    physician: principal,
    record-category: (string-ascii 64),
    data-volume: uint,
    accessed-volume: uint,
    created-at: uint,
    active-record: bool
  }
)

(define-map physician-records
  { physician: principal }
  { record-count: uint, total-data-managed: uint }
)

(define-map access-privileges
  { record-id: uint, medical-staff: principal }
  { can-access: bool, access-limit: uint }
)

;; Read-only functions
(define-read-only (get-medical-record (record-id uint))
  (map-get? medical-records { record-id: record-id })
)

(define-read-only (get-physician-stats (physician principal))
  (default-to 
    { record-count: u0, total-data-managed: u0 }
    (map-get? physician-records { physician: physician })
  )
)

(define-read-only (get-total-records)
  (var-get total-records)
)

(define-read-only (is-system-maintenance)
  (var-get system-maintenance)
)

(define-read-only (get-access-privilege (record-id uint) (medical-staff principal))
  (map-get? access-privileges { record-id: record-id, medical-staff: medical-staff })
)

(define-read-only (is-chief-medical-officer (user principal))
  (is-eq user chief-medical-officer)
)

;; Private functions
(define-private (update-physician-stats (physician principal) (data-size uint))
  (let
    (
      (current-stats (get-physician-stats physician))
      (new-count (+ (get record-count current-stats) u1))
      (new-total (+ (get total-data-managed current-stats) data-size))
    )
    (map-set physician-records
      { physician: physician }
      { record-count: new-count, total-data-managed: new-total }
    )
  )
)

;; Public functions
(define-public (create-medical-record (record-category (string-ascii 64)) (data-volume uint))
  (begin
    (asserts! (not (var-get system-maintenance)) (err u106))
    (asserts! (> data-volume u0) err-invalid-data-size)
    (asserts! (<= (len record-category) u64) (err u107))
    
    (let
      (
        (record-id (+ (var-get total-records) u1))
        (current-block stacks-block-height)
      )
      
      ;; Create new medical record
      (map-set medical-records
        { record-id: record-id }
        {
          physician: tx-sender,
          record-category: record-category,
          data-volume: data-volume,
          accessed-volume: u0,
          created-at: current-block,
          active-record: true
        }
      )
      
      ;; Update counters
      (var-set total-records record-id)
      (update-physician-stats tx-sender data-volume)
      
      (ok record-id)
    )
  )
)

(define-public (access-medical-data (record-id uint) (access-volume uint))
  (begin
    (asserts! (not (var-get system-maintenance)) (err u106))
    (asserts! (> access-volume u0) err-invalid-data-size)
    
    (let
      (
        (record-data (unwrap! (get-medical-record record-id) err-record-not-found))
        (current-accessed (get accessed-volume record-data))
        (total-volume (get data-volume record-data))
        (new-accessed (+ current-accessed access-volume))
      )
      
      ;; Verify record is active
      (asserts! (get active-record record-data) (err u108))
      
      ;; Verify sufficient clearance
      (asserts! (<= new-accessed total-volume) err-insufficient-clearance)
      
      ;; Check access privileges (physician can always access)
      (asserts! 
        (or 
          (is-eq tx-sender (get physician record-data))
          (match (get-access-privilege record-id tx-sender)
            privilege (and 
              (get can-access privilege)
              (<= access-volume (get access-limit privilege))
            )
            false
          )
        )
        err-unauthorized-access
      )
      
      ;; Update record
      (map-set medical-records
        { record-id: record-id }
        (merge record-data { accessed-volume: new-accessed })
      )
      
      (ok true)
    )
  )
)

(define-public (grant-medical-access (record-id uint) (medical-staff principal) (access-limit uint))
  (begin
    (let
      (
        (record-data (unwrap! (get-medical-record record-id) err-record-not-found))
      )
      
      ;; Only physician can grant access
      (asserts! (is-eq tx-sender (get physician record-data)) err-unauthorized-access)
      
      ;; Set privilege
      (map-set access-privileges
        { record-id: record-id, medical-staff: medical-staff }
        { can-access: true, access-limit: access-limit }
      )
      
      (ok true)
    )
  )
)

(define-public (revoke-medical-access (record-id uint) (medical-staff principal))
  (begin
    (let
      (
        (record-data (unwrap! (get-medical-record record-id) err-record-not-found))
      )
      
      ;; Only physician can revoke access
      (asserts! (is-eq tx-sender (get physician record-data)) err-unauthorized-access)
      
      ;; Remove privilege
      (map-delete access-privileges { record-id: record-id, medical-staff: medical-staff })
      
      (ok true)
    )
  )
)

(define-public (archive-record (record-id uint))
  (begin
    (let
      (
        (record-data (unwrap! (get-medical-record record-id) err-record-not-found))
      )
      
      ;; Only physician can archive
      (asserts! (is-eq tx-sender (get physician record-data)) err-unauthorized-access)
      
      ;; Archive record
      (map-set medical-records
        { record-id: record-id }
        (merge record-data { active-record: false })
      )
      
      (ok true)
    )
  )
)

(define-public (enable-maintenance)
  (begin
    (asserts! (is-eq tx-sender chief-medical-officer) err-cmo-only)
    (var-set system-maintenance true)
    (ok true)
  )
)

(define-public (disable-maintenance)
  (begin
    (asserts! (is-eq tx-sender chief-medical-officer) err-cmo-only)
    (var-set system-maintenance false)
    (ok true)
  )
)

;; Initialize contract
(begin
  (var-set total-records u0)
  (var-set system-maintenance false)
)