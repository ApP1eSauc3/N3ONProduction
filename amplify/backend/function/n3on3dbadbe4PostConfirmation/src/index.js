/**
 * @fileoverview
 *
 * This CloudFormation Trigger creates a handler which awaits the other handlers
 * specified in the `MODULES` env var, located at `./${MODULE}`.
 */

/**
 * The names of modules to load are stored as a comma-delimited string in the
 * `MODULES` env var.
 */
const moduleNames = parseModules(process.env.MODULES);
/**
 * The array of imported modules.
 */
const modules = moduleNames.map((name) => require(`./${name}`));

/**
 * Only plain module names from this folder — never a path (`../x`, `/x`):
 * a malformed MODULES value must not load code from elsewhere.
 */
function parseModules(raw) {
  const names = String(raw || '').split(',').map((n) => n.trim()).filter(Boolean);
  for (const name of names) {
    if (!/^[a-z0-9-]+$/i.test(name)) throw new Error(`invalid trigger module name: ${name}`);
  }
  return names;
}
exports._parseModules = parseModules;

/**
 * This async handler iterates over the given modules and awaits them.
 *
 * @see https://docs.aws.amazon.com/lambda/latest/dg/nodejs-handler.html#nodejs-handler-async
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 *
 */
exports.handler = async (event, context) => {
  /**
   * Instead of naively iterating over all handlers, run them concurrently with
   * `await Promise.all(...)`. This would otherwise just be determined by the
   * order of names in the `MODULES` var.
   */
  await Promise.all(modules.map((module) => module.handler(event, context)));
  return event;
};
