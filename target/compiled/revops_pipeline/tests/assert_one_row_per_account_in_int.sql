-- tests/assert_one_row_per_account_in_int.sql
--
-- Maqsad: int_accounts da har account_id uchun aynan BITTA qator bor.
-- Agar 1:N JOIN agregatsiya qilinmay qolgan bo'lsa — bu test uni tutib oladi.
--
-- Qoida: GROUP BY to'g'ri ishlaganida COUNT(*) hech qachon > 1 bo'lmaydi.

SELECT account_id, COUNT(*) AS cnt
FROM "revops_analytics"."revops_int"."int_accounts"
GROUP BY account_id
HAVING COUNT(*) > 1