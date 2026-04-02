-- tests/assert_no_duplicate_emails_in_staging.sql
--
-- Maqsad: stg_contacts da dedupe to'g'ri ishlagan — har emaildan
-- faqat bitta qator (email_row_num = 1) saqlanganini tekshiramiz.
--
-- Bu test muvaffaqiyatli bo'lsa → 0 qator qaytaradi.
-- Qator qaytarsa → test FAIL.

SELECT email, COUNT(*) AS cnt
FROM {{ ref('stg_contacts') }}
WHERE email_row_num = 1
  AND email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1
