DROP TABLE IF EXISTS TMP_TARGET
SELECT
T0.U_BookingNumber AS U_BookingNumber,
CASE
    WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN PRICING.U_GrossClientRates
    WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (PRICING.U_GrossClientRates / 1.12)
END AS U_GrossClientRatesTax

INTO TMP_TARGET

FROM [dbo].[@PCTP_POD] T0  WITH (NOLOCK)
LEFT JOIN [dbo].[@PCTP_PRICING] PRICING ON PRICING.U_BookingId = T0.U_BookingNumber
LEFT JOIN OCRD client ON T0.U_SAPClient = client.CardCode

-------->>SUMMARY_EXTRACT

UPDATE SUMMARY_EXTRACT
SET U_GrossClientRatesTax = TMP.U_GrossClientRatesTax
FROM TMP_TARGET TMP
WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber

-------->>DELETING TMP_TARGET

DROP TABLE IF EXISTS TMP_TARGET