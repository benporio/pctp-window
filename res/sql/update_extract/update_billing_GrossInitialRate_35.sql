-------->>CREATING TARGETS

DROP TABLE IF EXISTS TMP_TARGET_202309010631PM
SELECT
POD.U_BookingNumber,
CASE
    WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossClientRates, 0)
    WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossClientRates, 0) / 1.12)
END AS U_GrossInitialRate,
(
    CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossClientRates, 0)
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossClientRates, 0) / 1.12)
    END
) --BILLING.U_GrossInitialRate
+ ISNULL(PRICING.U_Demurrage, 0)
+ (ISNULL(PRICING.U_AddtlDrop,0) + 
ISNULL(PRICING.U_BoomTruck,0) + 
ISNULL(PRICING.U_Manpower,0) + 
ISNULL(PRICING.U_Backload,0))
+ ISNULL(BILLING.U_ActualBilledRate, 0)
+ ISNULL(BILLING.U_RateAdjustments, 0)
+ ISNULL(BILLING.U_ActualDemurrage, 0)
+ ISNULL(BILLING.U_ActualAddCharges, 0) AS U_TotalRecClients,
ISNULL((SELECT
    SUM(L.PriceAfVAT)
FROM OINV H WITH (NOLOCK)
    LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
WHERE H.CANCELED = 'N' AND L.ItemCode = POD.U_BookingNumber), 0) 
- ((
    CASE
        WHEN ISNULL(client.VatStatus,'Y') = 'Y' THEN ISNULL(PRICING.U_GrossClientRates, 0)
        WHEN ISNULL(client.VatStatus,'Y') = 'N' THEN (ISNULL(PRICING.U_GrossClientRates, 0) / 1.12)
    END
) --BILLING.U_GrossInitialRate
+ ISNULL(PRICING.U_Demurrage, 0)
+ (ISNULL(PRICING.U_AddtlDrop,0) + 
ISNULL(PRICING.U_BoomTruck,0) + 
ISNULL(PRICING.U_Manpower,0) + 
ISNULL(PRICING.U_Backload,0))
+ ISNULL(BILLING.U_ActualBilledRate, 0)
+ ISNULL(BILLING.U_RateAdjustments, 0)
+ ISNULL(BILLING.U_ActualDemurrage, 0)
+ ISNULL(BILLING.U_ActualAddCharges, 0)) AS U_VarAR
INTO TMP_TARGET_202309010631PM
FROM [dbo].[@PCTP_POD] POD WITH (NOLOCK)
    LEFT JOIN [dbo].[@PCTP_BILLING] BILLING ON POD.U_BookingNumber = BILLING.U_BookingId
    LEFT JOIN [dbo].[@PCTP_PRICING] PRICING ON POD.U_BookingNumber = PRICING.U_BookingId
    LEFT JOIN OCRD client ON POD.U_SAPClient = client.CardCode;

-------->>BILLING_EXTRACT

SELECT U_BookingId AS U_BookingNumber, U_GrossInitialRate, U_TotalRecClients, U_VarAR
INTO BILLING_EXTRACT_35_BAK_20230901PM
FROM BILLING_EXTRACT;

UPDATE BILLING_EXTRACT
SET U_GrossInitialRate = TMP.U_GrossInitialRate,
    U_TotalRecClients = TMP.U_TotalRecClients,
    U_VarAR = TMP.U_VarAR
FROM TMP_TARGET_202309010631PM TMP
WHERE TMP.U_BookingNumber = BILLING_EXTRACT.U_BookingNumber;

-------->>SUMMARY_EXTRACT

SELECT U_BookingNumber, U_TotalRecClients, U_VarAR
INTO SUMMARY_EXTRACT_35_BAK_20230901PM
FROM SUMMARY_EXTRACT;

UPDATE SUMMARY_EXTRACT
SET U_TotalRecClients = TMP.U_TotalRecClients,
    U_VarAR = TMP.U_VarAR
FROM TMP_TARGET_202309010631PM TMP
WHERE TMP.U_BookingNumber = SUMMARY_EXTRACT.U_BookingNumber;

-------->>PRICING_EXTRACT

SELECT U_BookingId AS U_BookingNumber, U_TotalRecClients, U_VarAR
INTO PRICING_EXTRACT_35_BAK_20230901PM
FROM PRICING_EXTRACT;

UPDATE PRICING_EXTRACT
SET U_TotalRecClients = TMP.U_TotalRecClients,
    U_VarAR = TMP.U_VarAR
FROM TMP_TARGET_202309010631PM TMP
WHERE TMP.U_BookingNumber = PRICING_EXTRACT.U_BookingNumber;

-------->>DELETING TMP_TARGET_202309010631PM

DROP TABLE IF EXISTS TMP_TARGET_202309010631PM