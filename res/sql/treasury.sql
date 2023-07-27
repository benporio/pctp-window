-- TREASURY
SELECT
    --COLUMNS
    T0.U_BookingId,
    T0.U_BookingDate,
    T0.U_TruckerName,
    T0.U_PaymentVoucher,
    T0.U_ORRefNo,
    T0.U_ActualPaymentDate,
    T0.U_PaymentReference,
    T0.U_PaymentStatus
    --COLUMNS
FROM [dbo].[@PCTP_TREASURY] T0  WITH (NOLOCK)