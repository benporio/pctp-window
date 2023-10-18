ALTER TABLE PCTP_UNIFIED ALTER COLUMN U_OtherPODDoc nvarchar(4000);

-------->>CREATING TARGETS

DROP TABLE IF EXISTS TMP_TARGET_20231018
SELECT
    POD.U_BookingNumber,
    CAST(SUBSTRING((
                SELECT DISTINCT CONCAT(', ', header.DocNum)  AS [text()]
    FROM INV1 line WITH (NOLOCK)
        LEFT JOIN (SELECT DocEntry, DocNum, CANCELED FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
    WHERE line.ItemCode = POD.U_BookingNumber
        AND header.CANCELED = 'N'
    FOR XML PATH (''), TYPE
            ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500)) AS U_DocNum,
    CAST(SUBSTRING((
                SELECT DISTINCT CONCAT(', ', header.DocNum)  AS [text()]
    FROM INV1 line WITH (NOLOCK)
        LEFT JOIN (SELECT DocEntry, DocNum, CANCELED FROM OINV WITH (NOLOCK)) header ON header.DocEntry = line.DocEntry
    WHERE line.ItemCode = POD.U_BookingNumber
        AND header.CANCELED = 'N'
    FOR XML PATH (''), TYPE
            ).value('text()[1]','nvarchar(max)'), 2, 1000) as nvarchar(500)) As U_ARDocNum,
    CAST(POD.U_OtherPODDoc as nvarchar(4000)) AS U_OtherPODDoc
INTO TMP_TARGET_20231018
FROM [dbo].[@PCTP_POD] POD WITH (NOLOCK)

-------->>PCTP_UNIFIED

UPDATE PCTP_UNIFIED
SET U_DocNum = TMP.U_DocNum,
    U_ARDocNum = TMP.U_ARDocNum,
    U_OtherPODDoc = TMP.U_OtherPODDoc
FROM TMP_TARGET_20231018 TMP
WHERE TMP.U_BookingNumber = PCTP_UNIFIED.U_BookingNumber;

-------->>DELETING TMP_TARGET_20231018

DROP TABLE IF EXISTS TMP_TARGET_20231018