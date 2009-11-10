<?php
/**
 * @file openpublish.profile
 *
 * TODO:
 *  - More general variable handling
 *  - Integrate Content for better block handling
 */

/**
 * Implementation of hook_profile_details()
 */
function openpublish_profile_details() {  
  return array(
    'name' => 'OpenPublish',
    'description' => st('The power of Drupal for today\'s online publishing from Phase2 Technology.'),
  );
} 

/**
 * Implementation of hook_profile_modules().
 */
function openpublish_profile_modules() {
  $core_modules = array(
    // Required core modules
    'block', 'filter', 'node', 'system', 'user',

    // Optional core modules.
    'dblog', 'blog', 'comment', 'help', 'locale', 'menu', 'openid', 'path',
	  'profile', 'search', 'statistics', 'taxonomy', 'translation', 'upload', 
  );

  $contributed_modules = array(
    //misc stand-alone, required by others
    'admin', 'rdf', 'token', 'gmap', 'devel', 'flickrapi', 'autoload', 'apture', 
    'fckeditor', 'flag', 'imce', 'mollom', 'nodewords', 'nodewords_basic', 'paging',
    'pathauto', 'tabs', 'login_destination', 'cmf', 'install_profile_api',

    //date
    'date_api', 'date', 'date_timezone',
  
    //imagecache
    'imageapi', 'imageapi_gd', 'imagecache', 'imagecache_ui',
  
    //cck
    'content', 'content_copy', 'content_permissions', 'emfield', 'emaudio', 'emimage', 
    'emvideo', 'fieldgroup', 'filefield', 'imagefield', 'link', 'number',
    'optionwidgets', 'text', 'nodereference', 'userreference',
	
    // Calais
    'calais_api', 'calais', 'calais_geo', 'calais_tagmods',
    
    // Feed API
    'feedapi', 'feedapi_node', 'feedapi_inherit', 'feedapi_mapper', 'parser_simplepie', 

    // More Like this
    'morelikethis', 'morelikethis_flickr', 'morelikethis_googlevideo', 'morelikethis_taxonomy',
    'morelikethis_yboss',
	
    //swftools
    'swftools', 'swfobject2', 'flowplayer3',
	
    //views
    'views', 'views_export', 'views_ui',

    // ctools, panels
	  'ctools', 'views_content', 'page_manager', 'panels', 'panels_node', 
  
    //topic hubs
    'topichubs', 'topichubs_calais_geo', 'topichubs_contributors', 'topichubs_most_comments',
    'topichubs_most_recent', 'topichubs_most_viewed', 'topichubs_panels', 'topichubs_recent_comments',
    'topichubs_related_topics',
	
    // Custom modules developed for OpenPublish
    'openpublish_core', 'openpublish_administration', 'openpublish_popular_terms',
  );

  return array_merge($core_modules, $contributed_modules);
} 

/**
 * Return a list of tasks that this profile supports.
 *
 * @return
 *   A keyed array of tasks the profile will perform during
 *   the final stage. The keys of the array will be used internally,
 *   while the values will be displayed to the user in the installer
 *   task list.
 */
function openpublish_profile_task_list() {
  global $conf;
  $conf['site_name'] = 'OpenPublish';
  $conf['site_footer'] = 'OpenPublish by '. l('Phase2 Technology', 'http://www.phase2technology.com', array('absolute' => TRUE));
  $conf['theme_settings'] = array(
    'default_logo' => 0,
    'logo_path' => 'sites/all/themes/openpublish_theme/images/openpublish-logo.png',
  );
  
  $tasks['op-configure-batch'] = st('Configure OpenPublish');
  return $tasks;
}

/**
 * Implementation of hook_profile_tasks().
 */
function openpublish_profile_tasks(&$task, $url) {
  $output = "";
  
  install_include(openpublish_profile_modules());

  if($task == 'profile') {
    drupal_set_title(t('OpenPublish Installation'));
    _openpublish_log(t('Starting Installation'));
    _openpublish_base_settings();
    $task = "op-configure";
  }
    
  if($task == 'op-configure') {
    $batch['title'] = st('Configuring @drupal', array('@drupal' => drupal_install_profile_name()));
    $cck_files = file_scan_directory ( dirname(__FILE__) . '/cck' , '.*\.inc$' );
    foreach ( $cck_files as $file ) {   
      $batch['operations'][] = array('_openpublish_import_cck', array($file));      
    }    
    $batch['operations'][] = array('_openpublish_set_permissions', array());      
    $batch['operations'][] = array('_openpublish_initialize_settings', array());      
    $batch['operations'][] = array('_openpublish_placeholder_content', array());      
    $batch['operations'][] = array('_openpublish_set_views', array());      
    $batch['operations'][] = array('_openpublish_install_menus', array());      
    $batch['operations'][] = array('_openpublish_setup_blocks', array());      
    $batch['operations'][] = array('_openpublish_cleanup', array());      
    $batch['error_message'] = st('There was an error configuring @drupal.', array('@drupal' => drupal_install_profile_name()));
    $batch['finished'] = '_openpublish_configure_finished';
    variable_set('install_task', 'op-configure-batch');
    batch_set($batch);
    batch_process($url, $url);
  }
     
  // Land here until the batches are done
  if ($task == 'op-configure-batch') {
    include_once 'includes/batch.inc';
    $output = _batch_page();
  }
    
  return $output;
} 

/**
 * Import process is finished, move on to the next step
 */
function _openpublish_configure_finished($success, $results) {
  _openpublish_log(t('OpenPublish has been installed.'));
  variable_set('install_task', 'profile-finished');
}

/**
 * Do some basic setup
 */
function _openpublish_base_settings() {  
  global $base_url;  
  
  $types = array(
    array(
      'type' => 'page',
      'name' => st('Page'),
      'module' => 'node',
      'description' => st("A <em>page</em>, similar in form to a <em>story</em>, is a simple method for creating and displaying information that rarely changes, such as an \"About us\" section of a website. By default, a <em>page</em> entry does not allow visitor comments and is not featured on the site's initial home page."),
      'custom' => TRUE,
      'modified' => TRUE,
      'locked' => FALSE,
      'help' => '',
      'min_word_count' => '',
    ),   
  );

  foreach ($types as $type) {
    $type = (object) _node_type_set_defaults($type);
    node_type_save($type);
  }

  // Default page to not be promoted and have comments disabled.
  variable_set('node_options_page', array('status'));
  variable_set('comment_page', COMMENT_NODE_DISABLED);

  // Theme related.  
  install_default_theme('openpublish_theme');
  install_admin_theme('slate');	
  variable_set('node_admin_theme', TRUE);    
  
  $theme_settings = variable_get('theme_settings', array());
  $theme_settings['toggle_node_info_page'] = FALSE;
  $theme_settings['default_logo'] = FALSE;
  $theme_settings['logo_path'] = 'sites/all/themes/openpublish_theme/images/logo.gif';
  variable_set('theme_settings', $theme_settings);    
  
  // Basic Drupal settings.
  variable_set('site_frontpage', 'node');
  variable_set('user_register', 1); 
  variable_set('user_pictures', '1');
  variable_set('statistics_count_content_views', 1);
  variable_set('filter_default_format', '2');
  
  _openpublish_log(st('Configured basic settings'));
}

/**
 * Import cck definitions from included files
 */
function _openpublish_import_cck($file, &$context) {   
  // blog type is from drupal, so modify it
  if ($file->name == 'blog') {
    install_add_existing_field('blog', 'field_teaser', 'text_textarea');
    install_add_existing_field('blog', 'field_show_author_info', 'optionwidgets_onoff');      
  }
  else if ($file->name == 'feed') {
    $content = array();
    ob_start();
    include $file->filename;
    ob_end_clean();
    $feed = (object)$content['type'];
    variable_set('feedapi_settings_feed', $feed->feedapi);
  }
  else {
    install_content_copy_import_from_file($file->filename);
  }
  
  $msg = st('Content Type @type setup', array('@type' => $file->name));
  _openpublish_log($msg);
  $context['message'] = $msg;
}  

/**
 * Create some content of type "page" as placeholders for content
 * and so menu items can be created
 */
function _openpublish_placeholder_content(&$context) {
  global $base_url;  

  $user = user_load(array('uid' => 1));
 
  $page = array (
    'type' => 'page',
    'language' => 'en',
    'uid' => 1,
    'status' => 1,
    'comment' => 0,
    'promote' => 0,
    'moderate' => 0,
    'sticky' => 0,
    'tnid' => 0,
    'translate' => 0,    
    'revision_uid' => 1,
    'title' => st('Default'),
    'body' => 'Placeholder',    
    'format' => 2,
    'name' => $user->name,
  );
  
  $about_us = (object) $page;
  $about_us->title = st('About Us');
  node_save($about_us);	
  
  $adverstise = (object) $page;
  $adverstise->title = st('Advertise');
  node_save($adverstise);	
  
  $subscribe = (object) $page;
  $subscribe->title = st('Subscribe');
  node_save($subscribe);	
  
  $rss = (object) $page;
  $rss->title = st('RSS Feeds List');
  $rss->body = '<p><strong>Articles</strong><ul><li><a href="'. $base_url . '/rss/articles/all">All Categories</a></li><li><a href="'. $base_url . '/rss/articles/Business">Business</a></li><li><a href="'. $base_url . '/rss/articles/Health">Health</a></li><li><a href="'. $base_url . '/rss/articles/Politics">Politics</a></li><li><a href="'. $base_url . '/rss/articles/Technology">Technology</a></li><li><a href="'. $base_url . '/rss/blogs">Blogs</a></li><li><a href="/rss/events">Events</a></li><li><a href="'. $base_url . '/rss/resources">Resources</a></li><li><a href="'. $base_url . '/rss/multimedia">Multimedia</a></li></p>';
  node_save($rss);
  
  $jobs = (object) $page;
  $jobs->title = st('Jobs');
  node_save($jobs);
  
  $store = (object) $page;
  $store->title = st('Store');
  node_save($store);
  
  $sitemap = (object) $page;
  $sitemap->title = st('Site Map');
  node_save($sitemap);
  
  $termsofuse = (object) $page;
  $termsofuse->title = st('Terms of Use');
  node_save($termsofuse);
  
  $privacypolicy = (object) $page;
  $privacypolicy->title = st('Privacy Policy');
  node_save($privacypolicy); 
  
  $start = (object) $page;
  $start->title = st('Getting Started');
  $start->body = '<h1>Welcome to your new OpenPublish Site.</h1>Initially your site does not have any content, and that is where the fun begins. Use the thin black administration menu across the top of the page to accomplish many of the tasks needed to get your site up and running in no time.<br/><br/><h3>To create content</h3>Select <em>Content Management</em> -> <em>Create Content</em> from the administration menu (remember that little black bar at the top of the page?) to get started.  You can create a variety of content, but to start out you may want to create a few simple <a href="'. $base_url . '/node/add/article">Articles</a> or import items from an <a href="'. $base_url . '/node/add/feed">RSS Feed</a><h3>To change configuration options</h3>Select <em>Site Configuration</em> from the administration menu to change various configuration options and settings on your site.<h3>To add other users</h3>Select <em>User Management</em> -> <em>Users</em> from the administration menu to add new users or change user roles and permissions.<h3>Need more help?</h3>Select <em>Help</em> from the administration menu to learn more about what you can do with your site.<br/><br/>Don\'t forget to look for more resources and documentation at the <a href="http://www.openpublishapp.com">OpenPublish</a> website.<br/><br/>ENJOY!!!!';  
  node_save($start);

  menu_rebuild();
  
  $context['message'] = st('Installed Content');
}

/**
 * Configure user/role/permission data
 */
function _openpublish_set_permissions(&$context){
  
  // Load the permissions export
  include_once dirname(__FILE__) . "/includes/openpublish.perms.inc";

  // Reformat data for use with install_add_permissions
  $role_perms = array();
  foreach ($openpublish_perms as $perm => $roles) {
    foreach ($roles as $role) {
      if(!isset($role_perms[$role])) {
        $role_perms[$role] = array();
      }
      $role_perms[$role][] = $perm;
    }
  }
  // Import the permissions for each role
  foreach ($role_perms as $role => $perms) {
    $rid = install_get_rid($role);
    install_add_permissions($rid, $perms);
  }
  
  db_query('INSERT INTO {users_roles} (uid, rid) VALUES (%d, %d)', 1, $admin_rid);
  
  // Profile Fields
  $profile_full_name = array(
    'title' => 'Full Name', 
	  'name' => 'profile_full_name',
    'category' => 'Author Info',
    'type' => 'textfield',
  	'required'=> 0,
  	'register'=> 0,
  	'visibility' => 2,		
  	'weight' => -10,	
  );
  $profile_job_title = array(
    'title' => 'Job Title', 
	  'name' => 'profile_job_title',
    'category' => 'Author Info',
    'type' => 'textfield',
  	'required'=> 0,
  	'register'=> 0,
  	'visibility' => 2,		
  	'weight' => -9,	
  );
  $profile_bio = array(
    'title' => 'Bio', 
	  'name' => 'profile_bio',
    'category' => 'Author Info',
    'type' => 'textarea',
  	'required'=> 0,
  	'register'=> 0,
  	'visibility' => 2,		
  	'weight' => -8,	
  );
  install_profile_field_add($profile_full_name);
  install_profile_field_add($profile_job_title);
  install_profile_field_add($profile_bio);
  
  $context['message'] = st('Configured Permissions');
}

/**
 * Set misc settings
 */
function _openpublish_initialize_settings(&$context){

  // Disable default Flag
  $flag = flag_get_flag('bookmarks');
  $flag->types = array();
  $flag->save();
  
  // Pathauto
  variable_set('pathauto_node_pattern', '[title-raw]');
  variable_set('pathauto_node_article_pattern', 'article/[title-raw]');
  variable_set('pathauto_node_blog_pattern', 'blog/[title-raw]');
  variable_set('pathauto_node_audio_pattern', 'audio/[title-raw]');
  variable_set('pathauto_node_event_pattern', 'event/[title-raw]');
  variable_set('pathauto_node_op_image_pattern', 'image/[title-raw]');
  variable_set('pathauto_node_package_pattern', 'package/[title-raw]');
  variable_set('pathauto_node_topichub_pattern', 'topic-hub/[title-raw]');
  variable_set('pathauto_node_video_pattern', 'video/[title-raw]');
  variable_set('pathauto_blog_pattern', 'blogs/[user-raw]');
  variable_set('pathauto_node_feeditem_pattern', 'feed-item/[title-raw]');
  variable_set('pathauto_node_twitter_item_pattern', 'twitter-item/[title-raw]');
 
  // Login Destination
  variable_set('ld_condition_type', 'pages');
  variable_set('ld_condition_snippet', 'user
user/login');
  variable_set('ld_url_type', 'snippet');
  variable_set('ld_destination', 0);
  variable_set('ld_url_destination', '
global $user;
foreach($user->roles as $id => $role) {
  if ($role == "administrator" || $role == "author" || $role == "editor" || $role == "web editor") {
    return "admin/settings/openpublish/content";
  }
}
return "user"');
  
  // Calais
  $calais_all = calais_api_get_all_entities();
  $calais_ignored = array('Anniversary', 'Currency', 'EmailAddress', 'FaxNumber', 'PhoneNumber', 'URL');
  $calais_used = array_diff($calais_all, $calais_ignored);
  
  $calais_entities = calais_get_entity_vocabularies();
  
  variable_set('calais_api_allow_searching', false);
  variable_set('calais_api_allow_distribution', false);
  variable_set('calais_applied_entities_global', drupal_map_assoc($calais_used));
  
  variable_set('calais_node_blog_process', 'AUTO');
  variable_set('calais_node_article_process', 'AUTO');
  variable_set('calais_node_audio_process', 'AUTO');
  variable_set('calais_node_video_process', 'AUTO');
  variable_set('calais_node_op_image_process', 'AUTO');
  variable_set('calais_node_resource_process', 'AUTO');
  variable_set('calais_node_event_process', 'AUTO');
  variable_set('calais_node_feeditem_process', 'AUTO');
  
  // Config feed items to use SemanticProxy by default
  variable_set('calais_semanticproxy_field_feeditem', 'calais_feedapi_node');
  
  $node_types = array('article', 'blog', 'audio', 'video', 'op_image', 'resource', 'event', 'feeditem');
  foreach($node_types as $key) {
    if(!empty($calais_entities)) {
      foreach ($calais_entities as $entity => $vid) {
        if (!in_array($entity, $calais_ignored)) {
          db_query("INSERT INTO {vocabulary_node_types} (vid, type) values('%d','%s') ", $vid, $key);
        }
      }
    }
  }
 
  variable_set('calais_threshold_article', '.25');
  variable_set('calais_threshold_audio', '.25');
  variable_set('calais_threshold_blog', '.25');
  variable_set('calais_threshold_event', '.25');
  variable_set('calais_threshold_feeditem', '.25');
  variable_set('calais_threshold_op_image', '.25');
  variable_set('calais_threshold_resource', '.25');
  variable_set('calais_threshold_video', '.25');
  
  // Calais Geo
  $geo_vocabs = array();
  foreach($calais_entities as $key => $value) {
    if ($key == 'ProvinceOrState' || $key == 'City' || $key == 'Country') {
      $geo_vocabs[$value] = $value;
    }
  }
  variable_set('gmap_default', array('width' => '100%', 'height' => '300px', 'zoom' => '5', 'maxzoom' => '14'));
  variable_set('calais_geo_vocabularies', $geo_vocabs);
  variable_set('calais_geo_nodes_enabled', array('blog'=>'blog', 'article'=>'article', 'audio'=>'audio',
  				'event'=>'event','op_image'=>'op_image', 'resource'=>'resource', 'video'=>'video'));

  // Calais Tagmods
  variable_set('calais_tag_blacklist', 'Other, Person Professional, Quotation, Person Political, Person Travel, Person Professional Past, Person Political Past');
  
  // MoreLikeThis
  $target_types = array('blog' => 'blog', 'article' => 'article', 'event' => 'event', 'resource' => 'resource');
  variable_set('morelikethis_taxonomy_threshold_article', '.25');
  variable_set('morelikethis_taxonomy_threshold_blog', '.25');
  variable_set('morelikethis_taxonomy_threshold_event', '.25');
  variable_set('morelikethis_taxonomy_threshold_resource', '.25');
  variable_set('morelikethis_taxonomy_target_types_resource', $target_types);
  variable_set('morelikethis_taxonomy_target_types_event', $target_types);
  variable_set('morelikethis_taxonomy_target_types_article', $target_types);
  variable_set('morelikethis_taxonomy_target_types_blog', $target_types);
  variable_set('morelikethis_taxonomy_enabled_resource', 1);
  variable_set('morelikethis_taxonomy_enabled_article', 1);
  variable_set('morelikethis_taxonomy_enabled_blog', 1);
  variable_set('morelikethis_taxonomy_enabled_event', 1);
  variable_set('morelikethis_taxonomy_count_article', '5');
  variable_set('morelikethis_taxonomy_count_event', '5');
  variable_set('morelikethis_taxonomy_count_blog', '5');
  variable_set('morelikethis_gv_content_type_article', 1);
  variable_set('morelikethis_gv_content_type_blog', 1);
  variable_set('morelikethis_gv_content_type_event', 1);
  variable_set('morelikethis_gv_content_type_resource', 1);
  variable_set('morelikethis_flickr_content_type_resource ', 1);
  variable_set('morelikethis_flickr_content_type_event', 1);
  variable_set('morelikethis_flickr_content_type_blog', 1);
  variable_set('morelikethis_flickr_content_type_article', 1);
  variable_set('morelikethis_calais_default', 1); 
  variable_set('morelikethis_calais_relevance', '.45');  
  
  // Topic Hubs
  variable_set('topic_hub_plugin_type_default', array('blog' => 'blog', 'article' => 'article' ,'audio' => 'audio',
    'event' => 'event', 'op_image' => 'op_image', 'video' => 'video'));
  variable_set('topichubs_contrib_ignore', array(1=>1));
  
  // SWF Tools
  variable_set('swftools_embed_method', 'swfobject2_replace');
  variable_set('swftools_flv_display', 'flowplayer3_mediaplayer');
  variable_set('swftools_flv_display_list', 'flowplayer3_mediaplayer'); 
  variable_set('swftools_media_display_list', 'flowplayer3_mediaplayer');
  variable_set('swftools_mp3_display', 'flowplayer3_mediaplayer');
  variable_set('swftools_mp3_display', 'flowplayer3_mediaplayer');
  variable_set('swftools_mp3_display_list', 'flowplayer3_mediaplayer');
  variable_set('emfield_emvideo_allow_youtube', 1);
  variable_set('flowplayer3_mediaplayer_file', 'flowplayer-3.1.1.swf');
  variable_set('flowplayer3_mediaplayer_stream_plugin', 'flowplayer.rtmp-3.0.2.swf');

  $msg = st('Setup general configuration');
  _openpublish_log($msg);
  $context['message'] = $msg;
}

/**
 * Load views
 */
function _openpublish_set_views() {
  views_include_default_views();
  
  //popular view is disabled by default, enable it
  $view = views_get_view('popular');
  $view->disabled = FALSE;
  $view->save();
} 

/**
 * Setup custom menus and primary links.
 */
function _openpublish_install_menus(&$context) {
  cache_clear_all();
  menu_rebuild();
  
  // TODO: Rework into new Dashboard
  $op_plid = install_menu_create_menu_item('admin/settings/openpublish/api-keys', 'OpenPublish Control Panel', 'Short cuts to important functionality.', 'navigation', 1, -49);
  install_menu_create_menu_item('admin/settings/openpublish/api-keys', 'API Keys', 'Calais, Apture and Flickr API keys.', 'navigation', $op_plid, 1);
  install_menu_create_menu_item('admin/settings/openpublish/calais-suite', 'Calais Suite', 'Administrative links to Calais, More Like This and Topic Hubs functionality.', 'navigation', $op_plid, 2);
  install_menu_create_menu_item('admin/settings/openpublish/content', 'Content Links', 'Administrative links to content, comment, feed and taxonomy management.', 'navigation', $op_plid, 3);

  // Primary Navigation
  install_menu_create_menu_item('<front>',             'Home',       '', 'primary-links', 0, 1);
  install_menu_create_menu_item('articles/Business',   'Business',   '', 'primary-links', 0, 2);
  install_menu_create_menu_item('articles/Health',     'Health',     '', 'primary-links', 0, 3);
  install_menu_create_menu_item('articles/Politics',   'Politics',   '', 'primary-links', 0, 4);
  install_menu_create_menu_item('articles/Technology', 'Technology', '', 'primary-links', 0, 5);
  install_menu_create_menu_item('blogs',               'Blogs',      '', 'primary-links', 0, 6);
  install_menu_create_menu_item('resources',           'Resources',  '', 'primary-links', 0, 7);
  install_menu_create_menu_item('events',              'Events',     '', 'primary-links', 0, 8);
  install_menu_create_menu_item('topic-hubs',          'Topic Hubs', '', 'primary-links', 0, 9);

  install_menu_create_menu('Footer Primary', 'footer-primary');
  install_menu_create_menu_item('articles/all', 'Latest News', '', 'menu-footer-primary', 0, 1);
  install_menu_create_menu_item('popular/all',  'Hot Topics',  '', 'menu-footer-primary', 0, 2);
  install_menu_create_menu_item('blogs',        'Blogs',       '', 'menu-footer-primary', 0, 3);
  install_menu_create_menu_item('resources',    'Resources',   '', 'menu-footer-primary', 0, 4);
  install_menu_create_menu_item('events',       'Events',      '', 'menu-footer-primary', 0, 5);

  install_menu_create_menu('Footer Secondary', 'footer-secondary');
  install_menu_create_menu_item('node/3', 'Subscribe',      '', 'menu-footer-secondary', 0, 1);
  install_menu_create_menu_item('node/2', 'Advertise',      '', 'menu-footer-secondary', 0, 2);
  install_menu_create_menu_item('node/5', 'Jobs',           '', 'menu-footer-secondary', 0, 3);
  install_menu_create_menu_item('node/6', 'Store',          '', 'menu-footer-secondary', 0, 4);
  install_menu_create_menu_item('node/1', 'About Us',       '', 'menu-footer-secondary', 0, 5);
  install_menu_create_menu_item('node/7', 'Site Map',       '', 'menu-footer-secondary', 0, 6);
  install_menu_create_menu_item('node/8', 'Terms of Use',   '', 'menu-footer-secondary', 0, 7);
  install_menu_create_menu_item('node/9', 'Privacy Policy', '', 'menu-footer-secondary', 0, 8);
  install_menu_create_menu_item('node/1', 'About Us',       '', 'menu-footer-secondary', 0, 9);

  install_menu_create_menu('Top Menu', 'top-menu'); 
  install_menu_create_menu_item('node/1', 'About Us',  '', 'menu-top-menu', 0, 1);
  install_menu_create_menu_item('node/2', 'Advertise', '', 'menu-top-menu', 0, 2);
  install_menu_create_menu_item('node/3', 'Subscribe', '', 'menu-top-menu', 0, 3);
  install_menu_create_menu_item('node/4', 'RSS',       '', 'menu-top-menu', 0, 4);
  
  $msg = st('Installed Menus');
  _openpublish_log($msg);
  $context['message'] = $msg;
} 

/**
 * Create custom blocks and set region and pages.
 * 
 * TODO: Rework this to use Context.
 */
function _openpublish_setup_blocks(&$context) {  
  global $theme_key, $base_url; 
  cache_clear_all();

  // Ensures that $theme_key gets set for new block creation
  $theme_key = 'openpublish_theme';

  // install the demo ad blocks  
  $ad_base = $base_url . '/sites/all/themes/openpublish_theme/images';
  $b1 = install_create_custom_block('<p id="credits"><a href="http://www.phase2technology.com/" target="_blank">Phase2 Technology</a></p>', 'Credits', FILTER_HTML_ESCAPE);
  $b2 = install_create_custom_block('<img src="' . $ad_base . '/placeholder_ad_banner.gif"/><div class="clear"></div>', 'Top Banner Ad', 2);
  $b3 = install_create_custom_block('<p><img src="' . $ad_base . '/placeholder_ad_rectangle.gif"/></p>', 'Right Block Square Ad', 2);
  $b4 = install_create_custom_block('<p><img src="' . $ad_base . '/placeholder_ad_rectangle.gif"/></p>', 'Homepage Ad Block 1', 2);
  $b5 = install_create_custom_block('<p><img src="' . $ad_base . '/placeholder_ad_rectangle.gif"/></p>', 'Homepage Ad Block 2', FILTER_HTML_ESCAPE);

  // Get these new boxes in blocks table
  install_init_blocks();

  install_set_block('block', $b1, 'openpublish_theme', 'footer',  - 2);
  install_set_block('block', $b2, 'openpublish_theme', 'header', -10);
  install_set_block('block', $b3, 'openpublish_theme', 'right', -8, NULL, 'admin*
topic-hub/*
package/*');
  install_set_block('block', $b4, 'openpublish_theme', 'homepage_right', -10);
  install_set_block('block', $b5, 'openpublish_theme', 'homepage_right', -8);  
 
  install_set_block('views', 'blogs-block_2', 'openpublish_theme', 'homepage_center', -10);
  install_set_block('views', 'multimedia-block_1', 'openpublish_theme', 'homepage_center', -9);
  install_set_block('views', 'resources-block_1', 'openpublish_theme', 'homepage_center', -8);
  install_set_block('views', 'twitter_items-block_1', 'openpublish_theme', 'homepage_center', -7);
  install_set_block('views', 'events-block_1', 'openpublish_theme', 'homepage_center', -6);
  install_set_block('views', 'articles-block_2', 'openpublish_theme', 'homepage_left', -10);
  install_set_block('views', 'articles-block_1', 'openpublish_theme', 'homepage_left', -9);
  install_set_block('views', 'feed_items-block_1', 'openpublish_theme', 'homepage_left', -8);
  install_set_block('views', 'most_viewed_by_taxonomy-block', 'openpublish_theme', 'right', -7);
  install_set_block('views', 'most_viewed_by_node_type-block', 'openpublish_theme', 'right', -6);
  install_set_block('views', 'most_viewed_multimedia-block', 'openpublish_theme', 'right', -5);
  install_set_block('views', 'most_commented_articles-block_1', 'openpublish_theme', 'right', -4);
  install_set_block('views', 'most_commented_blogs-block_1', 'openpublish_theme', 'right', -3);
  
  install_set_block('morelikethis', 'googlevideo', 'openpublish_theme', 'content', -10); 	  
  install_set_block('openpublish_popular_terms', '0', 'openpublish_theme', 'homepage_right', -9);
  install_set_block('openpublish_popular_terms', '1', 'openpublish_theme', 'homepage_right', -7);
  install_set_block('morelikethis', 'taxonomy', 'openpublish_theme', 'right', -10);
  install_set_block('morelikethis', 'flickr', 'openpublish_theme', 'right', -9);

  _openpublish_set_block_title('Google Videos Like This', 'morelikethis', 'taxonomy', 'openpublish_theme');
  _openpublish_set_block_title('Flickr Images Like This', 'morelikethis', 'flickr', 'openpublish_theme');
  _openpublish_set_block_title('Recommended Reading', 'morelikethis', 'taxonomy', 'openpublish_theme');
  _openpublish_set_block_title('Most Used Terms', 'openpublish_popular_terms', '0', 'openpublish_theme');
  _openpublish_set_block_title('Featured Topic Hubs', 'openpublish_popular_terms', '1', 'openpublish_theme');

  _openpublish_set_block_visibility('article/*
blog/*
resource/*
event/*', 1, 'morelikethis', 'googlevideo', 'openpublish_theme');
  _openpublish_set_block_visibility('article/*
blog/*
resource/*
event/*', 1, 'morelikethis', 'flickr', 'openpublish_theme');
  _openpublish_set_block_visibility('article/*
blog/*
resource/*
event/*', 1, 'morelikethis', 'taxonomy ', 'openpublish_theme');
  _openpublish_set_block_visibility('resources*
events*
blogs*', 1, 'views', 'most_viewed_by_node_type-block', 'openpublish_theme');
  _openpublish_set_block_visibility('admin
admin/*', 1, 'openpublish_administration', '0', 'openpublish_theme');
  _openpublish_set_block_visibility('articles/*', 1, 'views', 'most_commented_articles-block_1', 'openpublish_theme');
  _openpublish_set_block_visibility('blogs', 1, 'views', 'most_commented_blogs-block_1', 'openpublish_theme');
  _openpublish_set_block_visibility('articles*', 1, 'views', 'most_viewed_by_taxonomy-block', 'openpublish_theme');
  _openpublish_set_block_visibility('multimedia', 1, 'views', 'most_viewed_multimedia-block', 'openpublish_theme');
 
  install_disable_block('user', '0', 'openpublish_theme');
  install_disable_block('user', '1', 'openpublish_theme');
  install_disable_block('system', '0', 'openpublish_theme');
  
  //install_set_block('openpublish_administration', '0', 'openpublish', 'left', 0);
  //install_add_block_role('openpublish_administration', '0', install_get_rid('administrator'));
  //install_add_block_role('openpublish_administration', '0', install_get_rid('editor'));
  //install_add_block_role('openpublish_administration', '0', install_get_rid('author'));
  //install_add_block_role('openpublish_administration', '0', install_get_rid('web editor'));  
  
  $msg = st('Configured Blocks');
  _openpublish_log($msg);
  $context['message'] = $msg;
}

/**
 * Helper for setting a block's title only.
 */
function _openpublish_set_block_title($title, $module, $delta, $theme) {
  db_query("UPDATE {blocks} SET title = '%s' WHERE module = '%s' AND delta = '%s' AND theme= '%s'", $title, $module, $delta, $theme);
}

/**
 * Helper for setting a block's visibility.
 */
function _openpublish_set_block_visibility($pages, $vis, $module, $delta, $theme) {
    db_query("UPDATE {blocks} SET pages = '%s', visibility = %d WHERE module = '%s' AND delta = '%s' AND theme = '%s'", $pages, $vis, $module, $delta, $theme);
}

/**
 * Cleanup after the install
 */
function _openpublish_cleanup($success, $results) {
  // DO NOT call drupal_flush_all_caches(), it disables all themes
  drupal_rebuild_theme_registry();
  menu_rebuild();
  node_types_rebuild();
  install_init_blocks();
  views_invalidate_cache();
}

/**
 * Set OpenPublish as the default install profile
 */
function system_form_install_select_profile_form_alter(&$form, $form_state) {
  foreach($form['profile'] as $key => $element) {
    $form['profile'][$key]['#value'] = 'openpublish';
  }
}


/**
 * Consolidate logging.
 */
function _openpublish_log($msg) {
  error_log($msg);
  drupal_set_message($msg);
}
