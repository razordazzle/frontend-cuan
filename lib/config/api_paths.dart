class ApiPaths {
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const me = '/users/me';
  static const updateMe = '/users/me'; // PUT sama path /users/me
  // (opsional) watchlist:
  static const myWatchlist = '/users/me/watchlist';
  static String deleteWatch(String ticker) => '/users/me/watchlist/$ticker';
  static const register = '/auth/register';
  static const authCheck = '/auth/check';
  
  // contoh market:
  static const market = '/market'; // GET list
  static const marketTop = '/market/top';
  static String stockDetail(String ticker) => '/stocks/$ticker';

  //vbl
  static const vblPlaylists = '/vbl/playlists';
  static const vblVideos = '/vbl/videos';
  static const vblProgress = '/vbl/progress';

  // journals
  static const journals = '/journals';
  static String journalDetail(String id) => '/journals/$id';
  static String journalPreview(String id) => '/journals/$id/preview';
  static String journalAccess(String id) => '/journals/$id/access';

  static const communityLink = '/community/link';

  static const search = '/search';
}
