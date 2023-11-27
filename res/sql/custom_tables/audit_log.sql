DROP TABLE IF EXISTS PCTP_WINDOW_JSON_LOG
GO
CREATE TABLE PCTP_WINDOW_JSON_LOG
(
    _id BIGINT PRIMARY KEY IDENTITY,
    time_stamp DATETIME NOT NULL DEFAULT (GETDATE()),
    event_type NVARCHAR(max) NOT NULL,
    ref_id NVARCHAR(max) NOT NULL,
    json_data NVARCHAR(max),
    CONSTRAINT event_type_chk CHECK (event_type in ('UPDATE', 'CREATE_SO', 'CREATE_AR', 'CREATE_AP'))
);

-----> SAMPLE QUERY
-- SELECT
--     event_type,
--     time_stamp,
--     ref_id AS booking_id,
--     JSON_VALUE(json_data, '$.tab') AS tab,
--     JSON_VALUE(json_data, '$.userInfo.userName') AS edited_by,
--     JSON_QUERY(json_data, '$.old') AS old_data,
--     JSON_QUERY(json_data, '$.new') AS new_data,
--     JSON_VALUE(json_data, '$.relatedNativeQuery') AS related_native_query
-- FROM PCTP_WINDOW_JSON_LOG
-- WHERE ref_id = 'I23383674PYH'
-- ORDER BY time_stamp DESC