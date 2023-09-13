DROP TABLE IF EXISTS TMP_SAPClientBillingLogicExemption
GO
CREATE TABLE TMP_SAPClientBillingLogicExemption
(
    _id BIGINT PRIMARY KEY IDENTITY,
    Code NVARCHAR(500) NOT NULL,
    Name NVARCHAR(500) NOT NULL,
);

INSERT INTO TMP_SAPClientBillingLogicExemption
(Code, Name) VALUES ('136.01-C1', 'Star Paper Corporation');