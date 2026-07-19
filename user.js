//asdf/
//
/* You may copy+paste this file and use it as it is.
 *
 * If you make changes to your about:config while the program is running, the
 * changes will be overwritten by the user.js when the application restarts.
 *
 * To make lasting changes to preferences, you will have to edit the user.js.
 */

/****************************************************************************
 * Betterfox                                                                *
 * "Ad meliora"                                                             *
 * version: 150                                                             *
 * url: https://github.com/yokoffing/Betterfox                              *
 ****************************************************************************/

/****************************************************************************
 * SECTION: SECUREFOX                                                       *
 ****************************************************************************/
/** TRACKING PROTECTION ***/
user_pref("browser.contentblocking.category", "strict");
browser.tabs.unloadOnLowMemory 
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.uitour.enabled", false);
user_pref("privacy.globalprivacycontrol.enabled", true);

/** OCSP & CERTS / HPKP ***/
user_pref("security.OCSP.enabled", 0);
user_pref("privacy.antitracking.isolateContentScriptResources", true);
user_pref("security.csp.reporting.enabled", false);

/** SSL / TLS ***/
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("browser.xul.error_pages.expert_bad_cert", true);
user_pref("security.tls.enable_0rtt_data", false);

/** DISK AVOIDANCE ***/
user_pref("browser.cache.disk.enable", false);
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);
user_pref("media.memory_cache_max_size", 65536);
user_pref("browser.sessionstore.interval", 60000);

/** SHUTDOWN & SANITIZING ***/
user_pref("privacy.history.custom", true);
user_pref("browser.privatebrowsing.resetPBM.enabled", true);

/** SPECULATIVE LOADING ***/
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("network.prefetch-next", false);

/** SEARCH / URL BAR ***/
user_pref("browser.urlbar.trimHttps", true);
user_pref("browser.urlbar.untrimOnUserInteraction.featureGate", true);
user_pref("browser.search.separatePrivateDefault.ui.enabled", true);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.groupLabels.enabled", false);
user_pref("browser.formfill.enable", false);
user_pref("network.IDN_show_punycode", true);

/** HTTPS-ONLY MODE ***/
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_error_page_user_suggestions", true);

/** PASSWORDS ***/
user_pref("signon.formlessCapture.enabled", false);
user_pref("signon.privateBrowsingCapture.enabled", false);
user_pref("network.auth.subresource-http-auth-allow", 1);
user_pref("editor.truncate_user_pastes", false);

/** EXTENSIONS ***/
user_pref("extensions.enabledScopes", 5);

/** HEADERS / REFERERS ***/
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);

/** CONTAINERS ***/
user_pref("privacy.userContext.ui.enabled", true);

/** VARIOUS ***/
user_pref("pdfjs.enableScripting", false);

/** SAFE BROWSING ***/
user_pref("browser.safebrowsing.downloads.remote.enabled", false);

/** MOZILLA ***/
user_pref("permissions.default.desktop-notification", 2);
user_pref("permissions.default.geo", 2);
user_pref("geo.provider.network.url", "https://beacondb.net/v1/geolocate");
user_pref("browser.search.update", false);
user_pref("permissions.manager.defaultsUrl", "");
user_pref("extensions.getAddons.cache.enabled", false);

/** TELEMETRY ***/
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("datareporting.usage.uploadEnabled", false);

/** EXPERIMENTS ***/
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");

/** CRASH REPORTS ***/
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.tabs.unloadOnLowMemory", true);

/****************************************************************************
 * SECTION: PESKYFOX                                                        *
 ****************************************************************************/
/** MOZILLA UI ***/
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.profiles.enabled", true);

/** THEME ADJUSTMENTS ***/
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.compactmode.show", true);
user_pref("browser.privateWindowSeparation.enabled", false); // WINDOWS

/** AI ***/
user_pref("browser.ai.control.default", "blocked");
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.menu", false);
user_pref("browser.tabs.groups.smart.enabled", false);
user_pref("browser.ml.linkPreview.enabled", false);

/** FULLSCREEN NOTICE ***/
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
user_pref("full-screen-api.warning.timeout", 0);

/** URL BAR ***/
user_pref("browser.urlbar.trending.featureGate", false);

/** NEW TAB PAGE ***/
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);

/** DOWNLOADS ***/
user_pref("browser.download.manager.addToRecentDocs", false);

/** PDF ***/
user_pref("browser.download.open_pdf_attachments_inline", true);

/** TAB BEHAVIOR ***/
user_pref("browser.bookmarks.openInTabClosesMenu", false);
user_pref("browser.menu.showViewImageInfo", true);
user_pref("findbar.highlightAll", true);
user_pref("layout.word_select.eat_space_to_next_word", false);

/****************************************************************************
 * SECTION: SMOOTHFOX                                                       *
 ****************************************************************************/
// visit https://github.com/yokoffing/Betterfox/blob/main/Smoothfox.js
// Enter your scrolling overrides below this line:


/****************************************************************************
 * START: MY OVERRIDES                                                      *
 ****************************************************************************/
// [WARNING] GPU-accelerated settings below (WebRender, layer compositor, shader cache,
// canvas cache) keep the GPU active and prevent deep PCIe power states (D3cold).
// This improves rendering smoothness but increases power draw on battery.

/** FASTFOX ***/
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", true);

// GFX / Rendering
user_pref("gfx.content.skia-font-cache-size", 32);         // 32MB font cache; default=5
user_pref("gfx.webrender.all", true);                      // enable WebRender + features
user_pref("gfx.webrender.precache-shaders", true);         // smoother rendering (longer initial startup)
user_pref("gfx.webrender.layer-compositor", true);         // improves YouTube performance
user_pref("gfx.canvas.accelerated.cache-items", 4096);     // default=8192; Chrome=4096
user_pref("gfx.canvas.accelerated.cache-size", 512);       // default=256; Chrome=512

// Disk Cache (override Securefox disabling it)
user_pref("browser.cache.disk.enable", true);              // re-enable disk cache for speed
user_pref("browser.cache.disk.smart_size.enabled", false); // manual cache size control
user_pref("browser.cache.disk.capacity", 512000);          // 512MB disk cache; default=256000
user_pref("browser.cache.disk.max_entry_size", 51200);     // 50MB max per entry; DEFAULT
user_pref("browser.cache.disk.metadata_memory_limit", 16384); // 16MB; default=250KB
user_pref("browser.cache.jsbc_compression_level", 3);      // compress cached JS bytecode

// Memory Cache
user_pref("browser.cache.memory.capacity", 131072);        // 128MB RAM cache; default=32768
user_pref("browser.cache.memory.max_entry_size", 20480);   // 20MB max entry; default=5120
user_pref("browser.sessionhistory.max_total_viewers", 4);  // default=8

// Image Cache
user_pref("image.cache.size", 10485760);                   // 10MB image cache; default=5MB
user_pref("image.mem.decode_bytes_at_a_time", 65536);      // chunk size; default=16384
user_pref("image.mem.max_decoded_image_kb", 512000);       // 500MB decoded images

// Network
user_pref("network.buffer.cache.size", 65535);             // 64KB buffer; default=32768
user_pref("network.buffer.cache.count", 48);               // buffer count; default=24
user_pref("network.http.max-connections", 1800);           // default=900
user_pref("network.http.max-persistent-connections-per-server", 10); // default=6
user_pref("network.http.pacing.requests.enabled", false);  // disable request pacing
user_pref("network.dnsCacheEntries", 10000);               // default=800
user_pref("network.ssl_tokens_cache_capacity", 10240);     // TLS token cache; default=2048

// Process Count
user_pref("dom.ipc.processCount", 8);                      // shared content processes
user_pref("dom.ipc.processCount.webIsolated", 1);          // per-site-origin processes

/** ANIMATIONS ***/
user_pref("toolkit.cosmeticAnimations.enabled", false);  // disable all UI animations
user_pref("ui.prefersReducedMotion", 1);                 // prefers-reduced-motion (number type)
user_pref("sidebar.animation.enabled", false);           // disable sidebar slide animation

/** SIDEBAR ***/
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.verticalTabs.dragToPinPromo.dismissed", true);
user_pref("browser.engagement.sidebar-button.has-used", true);
user_pref("sidebar.new-sidebar.has-used", true);
user_pref("sidebar.old-sidebar.has-used", true);
user_pref("full-screen-api.ignore-widgets", true);

/** SEARCH BAR ***/
user_pref("browser.urlbar.scotchBonnet.enableOverride", false); // hide Google search icon / disable unified search button


/** SECUREFOX ***/
user_pref("privacy.trackingprotection.allow_list.convenience.enabled", false); // disable Strict allowlist of convenience features
user_pref("signon.rememberSignons", false); // disable password manager
user_pref("extensions.formautofill.addresses.enabled", false); // disable address manager
user_pref("extensions.formautofill.creditCards.enabled", false); // disable credit card manager
user_pref("browser.urlbar.suggest.recentsearches", true); //TODO  // unselect "Show recent searches" for clean UI
user_pref("browser.urlbar.showSearchSuggestionsFirst", false); // unselect "Show search suggestions ahead of browsing history in address bar results" for clean UI
user_pref("signon.management.page.breach-alerts.enabled", false); // extra hardening
user_pref("signon.autofillForms", false); // unselect "Autofill logins and passwords" for clean UI
user_pref("signon.generation.enabled", false); // unselect "Suggest and generate strong passwords" for clean UI
user_pref("signon.firefoxRelay.feature", ""); // unselect suggestions from Firefox Relay for clean UI
user_pref("browser.safebrowsing.downloads.enabled", false); // deny SB to scan downloads to identify suspicious files; local checks only
user_pref("browser.safebrowsing.downloads.remote.url", ""); // enforce no remote checks for downloads by SB
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false); // clean up UI; not needed in user.js if remote downloads are disabled
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false); // clean up UI; not needed in user.js if remote downloads are disabled
user_pref("browser.safebrowsing.allowOverride", false); // do not allow user to override SB
user_pref("browser.search.update", false); // do not update opensearch engines
user_pref("network.trr.confirmationNS", "skip"); // skip TRR confirmation request
user_pref("extensions.webextensions.restrictedDomains", ""); // remove Mozilla domains so adblocker works on pages
//user_pref("identity.fxaccounts.enabled", false); // disable Firefox Sync
user_pref("browser.firefox-view.feature-tour", "{\"screen\":\"\",\"complete\":true}"); // disable the Firefox View tour from popping up for new profiles
user_pref("accessibility.force_disabled", 1); // disable Accessibility features
user_pref("security.cert_pinning.enforcement_level", 2); // strict public key pinning
user_pref("captivedetect.canonicalURL", ""); // disable captive portal detection
user_pref("network.captive-portal-service.enabled", false); // disable captive portal detection
user_pref("network.connectivity-service.enabled", false); // disable captive portal detection
user_pref("browser.download.enableDeletePrivate", true); // Delete files downloaded in private browsing when all private windows are closed
user_pref("browser.download.deletePrivateChosen", true); // Delete files downloaded in private browsing when all private windows are closed
user_pref("browser.download.deletePrivate", true); // Delete files downloaded in private browsing when all private windows are closed

/** PESKYFOX ***/
user_pref("devtools.accessibility.enabled", false); // removes un-needed "Inspect Accessibility Properties" on right-click
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false); // Settings>Home>Firefox Home Content>Recent Activity>Shortcuts>Sponsored shortcuts
user_pref("browser.newtabpage.activity-stream.showSponsored", false); // Settings>Home>Firefox Home Content>Recent Activity>Recommended by Pocket>Sponsored Stories
user_pref("browser.newtabpage.activity-stream.section.highlights.includeBookmarks", false); // Settings>Home>Firefox Home Content>Recent Activity>Bookmarks
user_pref("browser.newtabpage.activity-stream.section.highlights.includeDownloads", false); // Settings>Home>Firefox Home Content>Recent Activity>Most Recent Download
user_pref("browser.newtabpage.activity-stream.section.highlights.includeVisited", false); // Settings>Home>Firefox Home Content>Recent Activity>Visited Pages
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false); // Settings>Home>Firefox Home Content>Recent Activity>Pages Saved to Pocket
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.widgets.enabled", false);
user_pref("browser.toolbars.bookmarks.visibility", "never"); // always hide bookmark bar
user_pref("browser.startup.homepage_override.mstone", "ignore"); // What's New page after updates; master switch
user_pref("browser.urlbar.suggest.history", true); // Browsing history; hide URL bar dropdown suggestions
user_pref("browser.urlbar.suggest.bookmark", true); // Bookmarks; hide URL bar dropdown suggestions
user_pref("browser.urlbar.suggest.openpage", true); // Open tabs; hide URL bar dropdown suggestions
user_pref("browser.urlbar.suggest.topsites", false); // Shortcuts; disable dropdown suggestions with empty query
user_pref("browser.urlbar.suggest.engines", false); // Search engines; tab-to-search
user_pref("browser.urlbar.quicksuggest.enabled", false); // hide Firefox Suggest UI in the settings
user_pref("browser.bookmarks.max_backups", 0); // minimize disk use; manually back-up
user_pref("view_source.wrap_long_lines", true);  // wrap source lines
user_pref("devtools.debugger.ui.editor-wrapping", true);  // wrap lines in devtools
user_pref("browser.zoom.full", false); // text-only zoom, not all elements on page
user_pref("layout.word_select.eat_space_to_next_word", false); // do not select the space next to a word when selecting a word
user_pref("browser.tabs.loadBookmarksInTabs", true); // force bookmarks to open in a new tab, not the current tab
user_pref("ui.key.menuAccessKey", 18); // remove underlined characters from various settings
user_pref("general.autoScroll", false); // disable unintentional behavior for middle click
user_pref("ui.SpellCheckerUnderlineStyle", 1); // [HIDDEN] dots for spell check errors
user_pref("media.videocontrols.picture-in-picture.display-text-tracks.size", "small"); // PiP
user_pref("media.videocontrols.picture-in-picture.urlbar-button.enabled", false); // PiP in address bar
user_pref("reader.parse-on-load.enabled", false); // disable reader mode
user_pref("browser.uiCustomization.horizontalTabsBackup", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"reset-pbm-toolbar-button\",\"unified-extensions-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"firefox-view-button\",\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"import-button\",\"personal-bookmarks\"]},\"seen\":[\"reset-pbm-toolbar-button\",\"developer-button\",\"screenshot-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"toolbar-menubar\",\"TabsToolbar\"],\"currentVersion\":24,\"newElementCount\":2}");
user_pref("browser.uiCustomization.horizontalTabstrip", "[\"firefox-view-button\",\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"]");
user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"reset-pbm-toolbar-button\",\"unified-extensions-button\",\"firefox-view-button\",\"alltabs-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[],\"vertical-tabs\":[\"tabbrowser-tabs\"],\"PersonalToolbar\":[\"import-button\",\"personal-bookmarks\"]},\"seen\":[\"reset-pbm-toolbar-button\",\"developer-button\",\"screenshot-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"toolbar-menubar\",\"TabsToolbar\"],\"currentVersion\":24,\"newElementCount\":2}");

/** NIGHTLY ***/
user_pref("privacy.userContext.enabled", false); // disable Containers functionality
user_pref("browser.crashReports.unsubmittedCheck.enabled", false); // true by default on NIGHTLY

/** NETWORK ***/
user_pref("network.trr.mode", 2); // enable TRR (with System fallback)
user_pref("network.trr.max-fails", 5); // lower max attempts to use DoH
user_pref("network.trr.uri", "https://mozilla.cloudflare-dns.com/dns-query");
user_pref("doh-rollout.disable-heuristics", true);
user_pref("network.http.rcwn.enabled", false);
user_pref("network.dnsCacheExpiration", 3600); // keep entries for 1 hour; default=60
user_pref("browser.sessionstore.interval", 900000); // save session every 15 minutes

/** LINUX ***/
user_pref("geo.provider.use_geoclue", false); // [LINUX]
user_pref("pdfjs.defaultZoomValue", "page-width"); // PDF zoom level

/****************************************************************************
 * END: BETTERFOX                                                           *
 ****************************************************************************/
