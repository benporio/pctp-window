ALTER TABLE PCTP_UNIFIED ALTER COLUMN bi_U_BillingTeam nvarchar(500);

-------->>CREATING TARGETS

DROP TABLE IF EXISTS TMP_TARGET_20231120
SELECT
    POD.U_BookingNumber,
    CAST(SUBSTRING((
        SELECT DISTINCT CONCAT(', ', CONCAT(billingTeam.firstName, ' ', billingTeam.lastName))  AS [text()]
        FROM INV1 line WITH (NOLOCK)
        LEFT JOIN (SELECT DocEntry, DocNum, CANCELED, OwnerCode FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
        LEFT JOIN (SELECT empID, firstName, lastName FROM OHEM WITH(NOLOCK)) billingTeam ON billingTeam.empID = header.OwnerCode
        WHERE line.ItemCode = POD.U_BookingNumber AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
    ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500)) As bi_U_BillingTeam
INTO TMP_TARGET_20231120
FROM [dbo].[@PCTP_POD] POD WITH (NOLOCK)

-------->>PCTP_UNIFIED

UPDATE PCTP_UNIFIED
SET bi_U_BillingTeam = TMP.bi_U_BillingTeam
FROM TMP_TARGET_20231120 TMP
WHERE TMP.U_BookingNumber = PCTP_UNIFIED.U_BookingNumber;

-------->>DELETING TMP_TARGET_20231120

DROP TABLE IF EXISTS TMP_TARGET_20231120