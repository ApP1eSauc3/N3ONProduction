/**
 * S3 upload trigger. Logs only the number of records and their event names:
 * object keys carry user ids (avatars/<sub>.jpg), and CloudWatch is not the
 * place for them (it logged the whole event before). Tolerates malformed
 * events instead of throwing (which made S3 retry the invocation).
 */
exports.handler = async function (event) {
  const records = Array.isArray(event && event.Records) ? event.Records : [];
  const names = [...new Set(records.map((r) => (r && r.eventName) || 'unknown'))];
  console.log(JSON.stringify({ msg: 'S3 event', records: records.length, eventNames: names }));
  return { processed: records.length };
};
