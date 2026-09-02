# Renames the grant in place instead of tearing it down and re-adding it.
# Safe to delete once every repo using this template has applied once.
moved {
  from = google_cloudfunctions2_function_iam_member._
  to   = google_cloudfunctions2_function_iam_member.function_invoker
}
