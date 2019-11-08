const Promise = require('bluebird');
const Readlines = require('n-readlines');

let core;

/**
 * Web server (express) route handler to get styles, sprites and fronts
 * @param req request object
 * @param res response object
 * @param next will be called if request is not handled
 */
function cacheExpiration(req, res, next) {
  const start = Date.now();

  return Promise.try(() =>
    Object.values(core.getSources().getSourceConfigs())
      .filter(source => source.uri.startsWith('cache://') && !source.isDisabled))
    .then((sources) => {
      res.type('text');
      const liner = new Readlines('/data/expire_tiles/expire_tiles.tiles');

      let x;
      let y;
      let z;
      let line;
      while (line = liner.next()) {
        [z, x, y] = line.toString('ascii').split('/');
        sources.forEach(source => source.getHandler().expireTile(z, x, y, null));
        res.write(`${line}\n`);
      }

      res.write('DONE\n');
      res.send();
      core.metrics.endTiming('cache_expiration', start);
    }).catch(err => core.reportRequestError(err, res)).catch(next);
}

module.exports = (cor, router) => {
  core = cor;
  router.get('/cache_expiration', cacheExpiration);
};
