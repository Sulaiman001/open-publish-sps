<?php

/**
 * Implementation of hook_profile_details()
 */
function openpublish_profile_details() {  
  return array(
    'name' => 'OpenPublish',
    'description' => st('The OpenPublish profile installs the semantic platform for publishers.'),
  );
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
  $conf['theme_settings'] = array(
    'default_logo' => 0,
    'logo_path' => 'profiles/openpublish/logo.png',
  );
  
  return array('api-info' => st('Calais API Key'));
}

/**
 * Implementation of hook_profile_modules()
 */
function openpublish_profile_modules() {
  $core_modules = array(
    // Required core modules
    'block', 'filter', 'node', 'system', 'user',

    // Optional core modules.
    'dblog','blog', 'comment', 'help', 'locale', 'menu', 'openid', 'path', 'ping', 
	  'profile', 'search', 'statistics', 'taxonomy', 'translation', 'upload', 'install_profile_api',
	  'php'
  );

  $contributed_modules = array(
    //misc stand-alone, required by others
    'admin_menu', 'rdf', 'token', 'gmap', 'devel', 'flickrapi', 'autoload', 'apture', 
    'fckeditor', 'flag', 'imce', 'login_destination', 'mollom', 'nodewords', 'paging',
    'pathauto', 'tabs',
  
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
    
    // 3rd-party integrations
    'contenture', 'quantcast',
	
    // Feed API
    'feedapi', 'feedapi_node', 'feedapi_inherit', 'feedapi_mapper', 'parser_simplepie', 

    // More Like this
    'morelikethis', 'morelikethis_flickr', 'morelikethis_googlevideo', 'morelikethis_taxonomy',
    'morelikethis_yboss',
	
    //swftools
    'swftools', 'swfobject2', 'flowplayer3',
	
    //views
    'views', 'views_export', 'views_ui',
	
    //topic hubs
    'ctools', 
    'views_content', 'page_manager', 'panels', 'panels_node', 
    'topichubs', 'topichubs_calais_geo', 'topichubs_contributors', 'topichubs_most_comments',
    'topichubs_most_recent', 'topichubs_most_viewed', 'topichubs_panels', 'topichubs_recent_comments',
    'topichubs_related_topics',
	
    // Custom modules developed for OpenPublish
    'openpublish_administration', 'popular_terms', 'openpublish_views',    
  );

  return array_merge($core_modules, $contributed_modules);
} 

/**
 * Implementation of hook_profile_tasks().
 */
function openpublish_profile_tasks(&$task, $url) {
  
  if($task == 'profile') {
    $task = 'api-info';
    drupal_set_title(st('Keys Configuration'));
    return drupal_get_form('key_settings', $url);
  }
  
  if($task == 'api-info') {
    // This takes a long time, so try to avoid a timeout.
    if (ini_get('max_execution_time') < 240) {
      set_time_limit(240);
    }
    
    // Save values from the API form
    $form_values = array('values' => $_POST);
    system_settings_form_submit(array(), $form_values);
    
    _openpublish_log(t('Kicking off installation'));
    install_include(openpublish_profile_modules());

    drupal_set_title(t('OpenPublish Installation'));
    _openpublish_base_settings();
    _openpublish_set_cck_types();
    _openpublish_initialize_settings();
    _openpublish_placeholder_content();
    _openpublish_set_views();
    _openpublish_modify_menus();
    _openpublish_setup_blocks();

    menu_rebuild();
    cache_clear_all();
    $task = 'profile-finished';
  }
} 

function key_settings($form_state, $url) {
  $form = array();

  $form['intro_message'] = array(
    '#value' => t('The following keys are needed in order to utilize all of the features of OpenPublish. If you do not enter these now, you can enter them after installation in their respective settings pages.'),
  );
   
   
  $calais_url = array(
    '!calais_url' => l(t('Get your key here'), 'http://www.opencalais.com/user/register', array('attributes' => array('target' => '_blank'))),
  );
  $form['calais'] = array(
    '#type' => 'fieldset',
    '#title' => t('Calais Configuration'),
    '#collapsible' => FALSE,
  );
  $form['calais']['intro'] = array(
     '#value' => t('The Calais Collection is an integration of the Thomson Reuters Calais web service into the Drupal platform. The Calais Web Service automatically creates rich semantic metadata for your content. !calais_url.', $calais_url),
  );
  $form['calais']['calais_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Calais API Key'),
    '#default_value' => $form_state['values']['calais_api_key'],
    '#size' => 60,
  );
  
  
  $flickr_url = array(
    '!flickr_url' => l(t('Get them here'), 'http://www.flickr.com/services/api/misc.api_keys.html', array('attributes' => array('target' => '_blank'))),
  );
  $form['flickr'] = array(
    '#type' => 'fieldset',
    '#title' => t('Flickr Configuration'),
    '#collapsible' => FALSE,
  );
  $form['flickr'] ['intro'] = array(
     '#value' => t('The More Like This module allows you to include related images from Flickr. To take advantage of this feature, you will need API keys from Flickr. !flickr_url.', $flickr_url),
  );
  $form['flickr']['flickrapi_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Flickr API Key'),
    '#default_value' => $form_state['values']['flickrapi_api_key'],
    '#size' => 60,
    '#description' => t('API Key from Flickr'),
  );
  $form['flickr']['flickrapi_api_secret'] = array(
    '#type' => 'textfield',
    '#title' => t('Flickr API Shared Secret'),
    '#default_value' => $form_state['values']['flickrapi_api_secret'],
    '#size' => 60,
    '#description' => t("API key's secret from Flickr."),
  );
  
  
  $yahoo_url = array(
    '!yahoo_url' => l(t('Learn more about Yahoo! BOSS'), 'http://developer.yahoo.com/search/boss/', array('attributes' => array('target' => '_blank'))),
  );
  $form['yahoo'] = array(
    '#type' => 'fieldset',
    '#title' => t('Yahoo! BOSS Configuration'),
    '#collapsible' => FALSE,
  );
  $form['yahoo'] ['intro'] = array(
     '#value' => t('The More Like This module allows you to incorporate content and images from Yahoo! BOSS. !yahoo_url.', $yahoo_url),
  );
  $form['yahoo']['morelikethis_yboss_appid'] = array(
    '#type' => 'textfield',
    '#title' => t('Yahoo! BOSS App ID'),
    '#default_value' => $form_state['values']['morelikethis_yboss_appid'],
    '#size' => 60,
  );
  $form['yahoo']['morelikethis_ybossimg_appid'] = array(
    '#type' => 'textfield',
    '#title' => t('Yahoo! BOSS Images App ID'),
    '#default_value' => $form_state['values']['morelikethis_ybossimg_appid'],
    '#size' => 60,
    '#description' => t('This can be the same as the regular App ID'),
  );
 
   
  $google_url = array(
    '!google_url' => l(t('Get it here'), 'http://code.google.com/apis/maps/index.html', array('attributes' => array('target' => '_blank'))),
  ); 
  $form['google'] = array(
    '#type' => 'fieldset',
    '#title' => t('Goolge Maps Configuration'),
    '#collapsible' => FALSE,
  );
  $form['google'] ['intro'] = array(
     '#value' => t('Calais Geo functionality allows mapping of your content. Topic Hubs take advantage of this feature. To utilize this functionality you will need a google maps API key. !google_url.', $google_url),
  );
  $form['google']['googlemap_api_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Goolge Maps API Key'),
    '#default_value' => $form_state['values']['googlemap_api_key'],
    '#size' => 60,
  );
  
  
  $mollom_url = array(
    '!mollom_url' => l(t('Sign up for Mollom'), 'http://mollom.com/user/register', array('attributes' => array('target' => '_blank'))),
  );
  $form['mollom'] = array(
    '#type' => 'fieldset',
    '#title' => t('Mollom'),
    '#collapsible' => FALSE,
  );
  $form['mollom'] ['intro'] = array(
     '#value' => t('Mollom is a service that is used to block spam from your forms. You need to sign up and register your site to obtain your keys. !mollom_url.', $mollom_url),
  );
  $form['mollom']['mollom_private_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Mollom Private Key'),
    '#default_value' => $form_state['values']['mollom_private_key'],
    '#size' => 60,
  );
  $form['mollom']['mollom_public_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Mollom Public Key'),
    '#default_value' => $form_state['values']['mollom_public_key'],
    '#size' => 60,
  );

  $form['mollom']['mollom_public_key'] = array(
    '#type' => 'textfield',
    '#title' => t('Mollom Public Key'),
    '#default_value' => $form_state['values']['mollom_public_key'],
    '#size' => 60,
  );


 $form['contenture'] = array(
    '#type' => 'fieldset',
    '#title' => t('Contenture'),
    '#collapsible' => FALSE,
  );
  
 $form['contenture']['intro'] = array(
     '#value' => t('Contenture is a revolutionary micropayments system. If you do not have Contenture Site ID and Database server information, please register with !url. Once you are registered, go to the control panel at: !dashboard, register this website\'s URL with Contenture and it will show you the site ID and database server for the website.',
                  array('!url' => l('contenture.com', 'http://contenture.com/user/register'),
                        '!dashboard' => l('http://contenture.com/user/','http://contenture.com/user/')
                       )
                  )
  );

 $form['contenture']['contenture_site_id'] = array(
    '#type' => 'textfield',
    '#title' => t('Contenture site ID'),
    '#default_value' => $form_state['values']['contenture_site_id'],
    '#size' => 60,
  );

  $form['contenture']['contenture_db_server'] = array(
    '#type' => 'textfield',
    '#title' => t('Contenture database server'),
    '#default_value' => $form_state['values']['contenture_db_server'],
    '#size' => 60,
  );
  
  
  $form['quantcast'] = array(
    '#type' => 'fieldset',
    '#title' => t('Quantcast'),
    '#collapsible' => FALSE,
  );
  
  $form['quantcast']['intro'] = array(
     '#value' => t('Quantcast is a powerful ad-targeting solution for publishers. If you do not already have a Quantcast Tag, please acquire it by registering at: !link', array('!link'=>l('http://www.quantcast.com/user/signup','http://www.quantcast.com/user/signup'))),
   );

  $form['quantcast']['quantcast_tag'] = array(
    '#type' => 'textarea',
    '#title' => t('Quantcast Tag'),
    '#default_value' => variable_get('quantcast_tag', ''),
    '#size' => 60,
    '#rows' => 7,
    '#description' => t('If you do not already have a Quantcast Tag, please acquire it by registering at: !link', array('!link'=>l('http://www.quantcast.com/user/signup','http://www.quantcast.com/user/signup'))),
  );
  
    
  $maxtime = ini_get('max_execution_time');
  
  $form['continue_message'] = array(
    '#type' => 'markup',
    '#value' => t('The next step, configuring your OpenPublish site, can take quite some time to complete. Please bear with us. Make sure your PHP setting for max_execution_time is 60 or greater. It is currently set to @time. We will also try setting it automatically, but server security settings might not allow it.', array('@time' => $maxtime)).'<br/>',
  );
  
  $form['submit'] = array(
    '#type' => 'submit',
    '#value' => st('Save and continue'),
  );
  
  $form['#action'] = $url;
  $form['#redirect'] = FALSE;
  return $form;
}

function key_settings_submit($form, &$form_state) {
  // Don't think this ever gets called.
}

/**
 * First function called by install process, just do some basic setup
 */
function _openpublish_base_settings() {  
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

  // Don't display date and author information for page nodes by default.
   // Theme related.  
  install_default_theme('openpublish');
  variable_set('admin_theme', 'rootcandy');	
  
  $theme_settings = variable_get('theme_settings', array());
  $theme_settings['toggle_node_info_page'] = FALSE;
  variable_set('theme_settings', $theme_settings);    
  
  _openpublish_log(t('Configured basic settings'));
}

/**
 * Import cck definitions from included files
 */
function _openpublish_set_cck_types() {   
  $cck_files = file_scan_directory ( dirname(__FILE__) . '/cck' , '.*\.inc$' );
  foreach ( $cck_files as $file ) {   
    if ($file->name == 'blog')
      continue;
      
    if ($file->name == 'feed') {
      _configure_feed_content_type($file->filename);
    }
    else {
      install_content_copy_import_from_file($file->filename);
    }
  }
  
  //"blog" type is from drupal, so modify it
  install_add_existing_field('blog', 'field_teaser', 'text_textarea');
  install_add_existing_field('blog', 'field_show_author_info', 'optionwidgets_onoff');
  
  _openpublish_log(t('Content Types added'));
}  

/**
 * Set some FeedAPI defaults. The built in defaults are not good (for us)
 */
function _configure_feed_content_type($file) {
  $content = array();
  ob_start();
  include $file;
  ob_end_clean();
  $feed = (object)$content['type'];
  variable_set('feedapi_settings_feed', $feed->feedapi);
  _openpublish_log(t('Updated FeedAPI Feed settings'));
}

/**
 * Create some content of type "page" as placeholders for content
 * and so menu items can be created
 */
function _openpublish_placeholder_content() {
  global $base_url;  

  $user_1 = user_load(array('uid' => 1));
  $user_1_name = $user_1->name;    
 
  $about_us = array (
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
    'title' => st('About Us'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $about_us = (object) $about_us;
  node_save($about_us);	
  
  $adverstise = array (
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
    'title' => st('Advertise'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $adverstise = (object) $adverstise;
  node_save($adverstise);	
  
  $subscribe = array (
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
    'title' => st('Subscribe'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $subscribe = (object) $subscribe;
  node_save($subscribe);	
  
  $rss = array (
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
    'title' => st('RSS Feeds List'),
    'body' => '<p><strong>Articles</strong><ul><li><a href="'. $base_url . '/rss/articles/all">All Categories</a></li><li><a href="'. $base_url . '/rss/articles/Business">Business</a></li><li><a href="'. $base_url . '/rss/articles/Health">Health</a></li><li><a href="'. $base_url . '/rss/articles/Politics">Politics</a></li><li><a href="'. $base_url . '/rss/articles/Technology">Technology</a></li><li><a href="'. $base_url . '/rss/blogs">Blogs</a></li><li><a href="/rss/events">Events</a></li><li><a href="'. $base_url . '/rss/resources">Resources</a></li><li><a href="'. $base_url . '/rss/multimedia">Multimedia</a></li></p>',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $rss = (object) $rss;
  node_save($rss);
  
  $jobs = array (
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
    'title' => st('Jobs'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $jobs = (object) $jobs;
  node_save($jobs);
  
  $store = array (
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
    'title' => st('Store'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $store = (object) $store;
  node_save($store);
  
  $sitemap = array (
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
    'title' => st('Site Map'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $sitemap = (object) $sitemap;
  node_save($sitemap);
  
  $termsofuse = array (
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
    'title' => st('Terms of Use'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $termsofuse = (object) $termsofuse;
  node_save($termsofuse);
  
  $privacypolicy = array (
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
    'title' => st('Privacy Policy'),
    'body' => 'Placeholder',    
    'format' => 1,
    'name' => $user_1_name,
  );
  $privacypolicy = (object) $privacypolicy;
  node_save($privacypolicy); 
  
  $start = array (
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
    'title' => st('Getting Started'),
    'body' => '<h1>Welcome to your new OpenPublish Site.</h1>Initially your site does not have any content, and that is where the fun begins. Use the thin black administration menu across the top of the page to accomplish many of the tasks needed to get your site up and running in no time.<br/><br/><h3>To create content</h3>Select <em>Content Management</em> -> <em>Create Content</em> from the administration menu (remember that little black bar at the top of the page?) to get started.  You can create a variety of content, but to start out you may want to create a few simple <a href="'. $base_url . '/node/add/article">Articles</a> or import items from an <a href="'. $base_url . '/node/add/feed">RSS Feed</a><h3>To change configuration options</h3>Select <em>Site Configuration</em> from the administration menu to change various configuration options and settings on your site.<h3>To add other users</h3>Select <em>User Management</em> -> <em>Users</em> from the administration menu to add new users or change user roles and permissions.<h3>Need more help?</h3>Select <em>Help</em> from the administration menu to learn more about what you can do with your site.<br/><br/>Don\'t forget to look for more resources and documentation at the <a href="http://www.opensourceopenminds.com/openpublish">OpenPublish</a> website.<br/><br/>ENJOY!!!!',    
    'format' => 2,
    'name' => $user_1_name,
  );
  $start = (object) $start;
  node_save($start);

  menu_rebuild();
  _openpublish_log(t('Placeholder content created'));
}

/**
 * Set roles and permissions and other misc settins
 */
function _openpublish_initialize_settings(){
  // Add roles
  install_add_role('administrator');
  install_add_role('editor');
  install_add_role('author');
  install_add_role('web editor');

  $admin_rid = install_get_rid('administrator');
  $editor_rid = install_get_rid('editor');
  $author_rid = install_get_rid('author');
  $webed_rid = install_get_rid('web editor');
  $anon_rid = install_get_rid('anonymous user');
  $auth_rid = install_get_rid('authenticated user');
  
  install_add_permissions($anon_rid, array('access calais rdf', 'access comments','view field_audio_file',
  		'view field_author','view field_center_intro','view field_center_main_image',
		'view field_center_related','view field_center_title','view field_deck',
		'view field_embedded_audio','view field_embedded_video','view field_event_date',
		'view field_flash_file','view field_left_intro','view field_left_related',
		'view field_links','view field_main_image','view field_right_intro',
		'view field_right_related','view field_show_author_info','view field_teaser',
		'view field_thumbnail_image','view imagefield uploads, access content',
		'search content','view uploaded files','access user profiles'));		
		
  install_add_permissions($auth_rid, array('access calais rdf', 'access comments','post comments','post comments without approval',
  		'view field_audio_file','view field_author','view field_center_intro',
		'view field_center_main_image','view field_center_related','view field_center_title',
		'view field_deck','view field_embedded_audio','view field_embedded_video',
		'view field_event_date','view field_flash_file','view field_left_intro',
		'view field_left_related','view field_links','view field_main_image, view field_right_intro',
		'view field_right_related','view field_show_author_info','view field_teaser',
		'view field_thumbnail_image','view imagefield uploads','access content, search content',
		'view uploaded files','access user profiles'));		
		
  install_add_permissions($admin_rid, array('access administration menu','display drupal links, administer apture',
  		'administer blocks','use PHP for block visibility','create blog entries',
		'delete any blog entry','delete own blog entries','edit any blog entry',
		'edit own blog entries','access calais', 'access calais rdf','administer calais',
		'administer calais api','administer calais geo','access comments','administer comments',
		'post comments','post comments without approval','Use PHP input for field settings (dangerous - grant with care)',
		'edit field_audio_file','edit field_author','edit field_center_intro',
		'edit field_center_main_image','edit field_center_related','edit field_center_title',
		'edit field_deck','edit field_embedded_audio','edit field_embedded_video','edit field_event_date',
		'edit field_flash_file','edit field_left_intro','edit field_left_related','edit field_links',
		'edit field_main_image','edit field_right_intro','edit field_right_related',
		'edit field_show_author_info','edit field_teaser','edit field_thumbnail_image',
		'view field_audio_file','view field_author','view field_center_intro','view field_center_main_image',
		'view field_center_related','view field_center_title','view field_deck','view field_embedded_audio',
		'view field_embedded_video','view field_event_date','view field_flash_file','view field_left_intro',
		'view field_left_related','view field_links','view field_main_image','view field_right_intro',
		'view field_right_related','view field_show_author_info','view field_teaser','view field_thumbnail_image',
		'administer custompage','edit custompage tiles','access devel information','display source code',
		'execute php code','switch users','access fckeditor','administer fckeditor','allow fckeditor file uploads',
		'administer feedapi','advanced feedapi options','administer filters','administer flags',
		'administer imageapi','administer imagecache','flush imagecache','view imagecache featured_image',
		'view imagecache package_featured','view imagecache spotlight_homepage','view imagecache thumbnail',
		'view imagefield uploads','administer languages','translate interface','administer login destination',
		'administer menu','post with no checking','administer morelikethis','access content',
		'administer content types','administer nodes','create article content','create audio content',
		'create event content','create feed content','create feeditem content','create op_image content',
		'create package content','create page content','create resource content','create topichub content',
		'create twitter_item content','create video content','delete any article content',
		'delete any audio content','delete any event content','delete any feed content',
		'delete any feeditem content','delete any op_image content','delete any package content',
		'delete any page content','delete any resource content','delete any topichub content',
		'delete any twitter_item content','delete any video content','delete own article content',
		'delete own audio content','delete own event content','delete own feed content',
		'delete own feeditem content','delete own op_image content','delete own package content',
		'delete own page content','delete own resource content','delete own topichub content',
		'delete own twitter_item content','delete own video content','delete revisions',
		'edit any article content','edit any audio content','edit any event content',
		'edit any feed content','edit any feeditem content','edit any op_image content',
		'edit any package content','edit any page content','edit any resource content',
		'edit any topichub content','edit any twitter_item content','edit any video content',
		'edit own article content','edit own audio content','edit own event content',
		'edit own feed content','edit own feeditem content','edit own op_image content',
		'edit own package content','edit own page content','edit own resource content',
		'edit own topichub content','edit own twitter_item content',
		'edit own video content','revert revisions','view revisions','administer meta tags',
		'edit meta tags','access openpublish admin pages','set api keys',
		'administer url aliases','create url aliases','administer pathauto',
		'notify of path changes','access RDF data','administer RDF data',
		'administer RDF namespaces','administer RDF repositories','export RDF data',
		'import RDF data','administer search','search content','use advanced search',
		'access statistics','view post access counter','administer flash',
		'access administration pages','access site reports','administer actions',
		'administer files','administer site configuration','select different theme',
		'administer taxonomy','administer topichubs','translate content','upload files',
		'view uploaded files','access user profiles','administer permissions',
		'administer users','change own username','administer views','use views exporter',
		'access all views','override node priority','override term priority',
		'administer advanced pane settings', 'administer pane access', 'administer pane visibility',
		'use panels caching features', 'view all panes', 'view pane admin links',
		'administer panel-node', 'create panel-nodes', 'edit own panel-nodes', 'administer panel-nodes'));
  
  install_add_permissions($editor_rid, array('access administration menu','display drupal links',
  		'create blog entries','delete any blog entry','delete own blog entries',
		'edit any blog entry','edit own blog entries','access calais', 'access calais rdf', 'access comments',
		'administer comments','post comments','post comments without approval',
		'edit field_audio_file','edit field_author','edit field_center_intro',
		'edit field_center_main_image','edit field_center_related',
		'edit field_center_title','edit field_deck','edit field_embedded_audio',
		'edit field_embedded_video','edit field_event_date','edit field_flash_file',
		'edit field_left_intro','edit field_left_related','edit field_links',
		'edit field_main_image','edit field_right_intro','edit field_right_related',
		'edit field_show_author_info','edit field_teaser','edit field_thumbnail_image',
		'view field_audio_file','view field_author','view field_center_intro',
		'view field_center_main_image','view field_center_related',
		'view field_center_title','view field_deck','view field_embedded_audio',
		'view field_embedded_video','view field_event_date','view field_flash_file',
		'view field_left_intro','view field_left_related','view field_links',
		'view field_main_image','view field_right_intro','view field_right_related',
		'view field_show_author_info','view field_teaser','view field_thumbnail_image',
		'edit custompage tiles','access fckeditor','allow fckeditor file uploads',
		'view imagecache featured_image','view imagecache package_featured',
		'view imagecache spotlight_homepage','view imagecache thumbnail',
		'view imagefield uploads','translate interface','administer menu',
		'post with no checking','administer morelikethis','access content',
		'administer nodes','create article content','create audio content',
		'create event content','create feed content','create feeditem content',
		'create op_image content','create package content','create page content',
		'create resource content','create topichub content','create twitter_item content',
		'create video content','delete any article content','delete any audio content',
		'delete any event content','delete any feed content','delete any feeditem content',
		'delete any op_image content','delete any package content',
		'delete any page content','delete any resource content','delete any topichub content',
		'delete any twitter_item content','delete any video content',
		'delete own article content','delete own audio content','delete own event content',
		'delete own feed content','delete own feeditem content','delete own op_image content',
		'delete own package content','delete own page content','delete own resource content',
		'delete own topichub content','delete own twitter_item content','delete own video content',
		'delete revisions','edit any article content','edit any audio content',
		'edit any event content','edit any feed content','edit any feeditem content',
		'edit any op_image content','edit any package content','edit any page content',
		'edit any resource content','edit any topichub content','edit any twitter_item content',
		'edit any video content','edit own article content','edit own audio content',
		'edit own event content','edit own feed content','edit own feeditem content',
		'edit own op_image content','edit own package content','edit own page content',
		'edit own resource content','edit own topichub content',
		'edit own twitter_item content','edit own video content','revert revisions',
		'view revisions','administer meta tags','edit meta tags',
		'access openpublish admin pages','create url aliases','administer pathauto',
		'search content','use advanced search','access statistics',
		'view post access counter','access administration pages','access site reports',
		'administer files','administer taxonomy','administer topichubs','translate content',
		'upload files','view uploaded files','access user profiles','administer users',
		'change own username','override node priority','override term priority'));  

  install_add_permissions($author_rid, array('access administration menu','display drupal links',
  		'create blog entries','delete own blog entries','edit own blog entries',
		'access calais', 'access calais rdf', 'access comments','administer comments','post comments',
		'post comments without approval','edit field_audio_file','edit field_author',
		'edit field_center_intro','edit field_center_main_image',
		'edit field_center_related','edit field_center_title','edit field_deck',
		'edit field_embedded_audio','edit field_embedded_video','edit field_event_date',
		'edit field_flash_file','edit field_left_intro','edit field_left_related',
		'edit field_links','edit field_main_image','edit field_right_intro',
		'edit field_right_related','edit field_show_author_info','edit field_teaser',
		'edit field_thumbnail_image','view field_audio_file','view field_author',
		'view field_center_intro','view field_center_main_image',
		'view field_center_related','view field_center_title','view field_deck',
		'view field_embedded_audio','view field_embedded_video','view field_event_date',
		'view field_flash_file','view field_left_intro','view field_left_related',
		'view field_links','view field_main_image','view field_right_intro',
		'view field_right_related','view field_show_author_info','view field_teaser',
		'view field_thumbnail_image','access fckeditor','allow fckeditor file uploads',
		'view imagecache featured_image','view imagecache package_featured',
		'view imagecache spotlight_homepage','view imagecache thumbnail',
		'view imagefield uploads','translate interface','post with no checking',
		'access content','create article content','create audio content',
		'create event content','create feed content','create feeditem content',
		'create op_image content','create package content','create page content',
		'create resource content','create topichub content','create twitter_item content',
		'create video content','delete own article content','delete own audio content',
		'delete own event content','delete own feed content','delete own feeditem content',
		'delete own op_image content','delete own package content',
		'delete own page content','delete own resource content',
		'delete own topichub content','delete own twitter_item content',
		'delete own video content','edit own article content','edit own audio content',
		'edit own event content','edit own feed content','edit own feeditem content',
		'edit own op_image content','edit own package content','edit own page content',
		'edit own resource content','edit own topichub content',
		'edit own twitter_item content','edit own video content','revert revisions',
		'view revisions','edit meta tags','access openpublish admin pages',
		'search content','use advanced search','access statistics',
		'view post access counter','access administration pages','access site reports',
		'translate content','upload files','view uploaded files','access user profiles'));
  
  install_add_permissions($webed_rid, array('access administration menu','display drupal links',
  		'administer apture','administer blocks','use PHP for block visibility',
		'create blog entries','delete any blog entry','delete own blog entries',
		'edit any blog entry','edit own blog entries','access calais', 'access calais rdf', 'administer calais',
		'access comments','administer comments','post comments',
		'post comments without approval','edit field_audio_file','edit field_author',
		'edit field_center_intro','edit field_center_main_image',
		'edit field_center_related','edit field_center_title','edit field_deck',
		'edit field_embedded_audio','edit field_embedded_video','edit field_event_date',
		'edit field_flash_file','edit field_left_intro','edit field_left_related',
		'edit field_links','edit field_main_image','edit field_right_intro',
		'edit field_right_related','edit field_show_author_info','edit field_teaser',
		'edit field_thumbnail_image','view field_audio_file','view field_author',
		'view field_center_intro','view field_center_main_image',
		'view field_center_related','view field_center_title','view field_deck',
		'view field_embedded_audio','view field_embedded_video','view field_event_date',
		'view field_flash_file','view field_left_intro','view field_left_related',
		'view field_links','view field_main_image','view field_right_intro',
		'view field_right_related','view field_show_author_info','view field_teaser',
		'view field_thumbnail_image','administer custompage','edit custompage tiles',
		'access fckeditor','allow fckeditor file uploads','administer feedapi',
		'view imagecache featured_image','view imagecache package_featured',
		'view imagecache spotlight_homepage','view imagecache thumbnail',
		'view imagefield uploads','administer languages','translate interface',
		'administer menu','post with no checking','administer morelikethis',
		'access content','administer content types','administer nodes',
		'create article content','create audio content','create event content',
		'create feed content','create feeditem content','create op_image content',
		'create package content','create page content','create resource content',
		'create topichub content','create twitter_item content','create video content',
		'delete any article content','delete any audio content',
		'delete any event content','delete any feed content',
		'delete any feeditem content','delete any op_image content',
		'delete any package content','delete any page content',
		'delete any resource content','delete any topichub content',
		'delete any twitter_item content','delete any video content',
		'delete own article content','delete own audio content','delete own event content',
		'delete own feed content','delete own feeditem content',
		'delete own op_image content','delete own package content',
		'delete own page content','delete own resource content',
		'delete own topichub content','delete own twitter_item content',
		'delete own video content','delete revisions','edit any article content',
		'edit any audio content','edit any event content','edit any feed content',
		'edit any feeditem content','edit any op_image content',
		'edit any package content','edit any page content',
		'edit any resource content','edit any topichub content',
		'edit any twitter_item content','edit any video content',
		'edit own article content','edit own audio content','edit own event content',
		'edit own feed content','edit own feeditem content','edit own op_image content',
		'edit own package content','edit own page content','edit own resource content',
		'edit own topichub content','edit own twitter_item content',
		'edit own video content','revert revisions','view revisions',
		'administer meta tags','edit meta tags','access openpublish admin pages',
		'administer url aliases','create url aliases','administer pathauto',
		'search content','use advanced search','access statistics',
		'view post access counter','administer flash','access administration pages',
		'access site reports','administer taxonomy','administer topichubs',
		'translate content','upload files','view uploaded files',
		'access user profiles','change own username','administer views',
		'access all views','override node priority','override term priority'));  
  
  db_query('INSERT INTO {users_roles} (uid, rid) VALUES (%d, %d)', 1, $admin_rid);

  //Image cache
  $imagecachepreset = imagecache_preset_save(array('presetname' => 'featured_image'));
  $imagecacheaction = new stdClass ();
  $imagecacheaction->presetid = $imagecachepreset['presetid'];
  $imagecacheaction->module = 'imagecache';
  $imagecacheaction->action = 'imagecache_scale';
  $imagecacheaction->data = array('width' => '200', 'height' => '', 'upscale' => 1);
  drupal_write_record('imagecache_action', $imagecacheaction);
  
  $imagecachepreset = imagecache_preset_save(array('presetname' => 'thumbnail'));
  $imagecacheaction = new stdClass ();
  $imagecacheaction->presetid = $imagecachepreset['presetid'];
  $imagecacheaction->module = 'imagecache';
  $imagecacheaction->action = 'imagecache_scale';
  $imagecacheaction->data = array('width' => '100', 'height' => '', 'upscale' => 1);
  drupal_write_record('imagecache_action', $imagecacheaction);
  
  $imagecachepreset = imagecache_preset_save(array('presetname' => 'spotlight_homepage'));
  $imagecacheaction = new stdClass ();
  $imagecacheaction->presetid = $imagecachepreset['presetid'];
  $imagecacheaction->module = 'imagecache';
  $imagecacheaction->action = 'imagecache_scale';
  $imagecacheaction->data = array('width' => '290', 'height' => '', 'upscale' => 1);
  drupal_write_record('imagecache_action', $imagecacheaction);
  
  $imagecachepreset = imagecache_preset_save(array('presetname' => 'package_featured'));
  $imagecacheaction = new stdClass ();
  $imagecacheaction->presetid = $imagecachepreset['presetid'];
  $imagecacheaction->module = 'imagecache';
  $imagecacheaction->action = 'imagecache_scale';
  $imagecacheaction->data = array('width' => '425', 'height' => '', 'upscale' => 0);
  drupal_write_record('imagecache_action', $imagecacheaction);
     
 
  //Pathauto
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
 
  //login destination
  variable_set('ld_url_type', 'snippet');
  variable_set('ld_condition_type', 'pages');
  variable_set('ld_condition_snippet', 'user
user/login');
  variable_set('ld_url_destination', 'global $user;
    $login_url = "user";
    foreach($user->roles as $id => $role) {
      if ($role == "administrator" || $role == "author" || $role == "editor" || $role == "web editor") $login_url = "admin/settings/openpublish/content";
    }
    return $login_url;');
  variable_set('ld_destination', 0);
  
  //profile fields
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
 
  //Calais Settings
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
  
  //MoreLikeThis Settings
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
  
  //Topic Hubs Settings
  variable_set('topic_hub_plugin_type_default', array('blog' => 'blog', 'article' => 'article' ,'audio' => 'audio',
    'event' => 'event', 'op_image' => 'op_image', 'video' => 'video'));
  variable_set('topichubs_contrib_ignore', array(1=>1));
  
  // Basic Drupal settings.
  variable_set('site_frontpage', 'node');
  variable_set('user_register', 1); 
  variable_set('statistics_count_content_views', 1);
 
  //swf tool settings
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
  
  // default filter to full 
  variable_set('filter_default_format', '2');

  variable_set('user_pictures', '1');

  _openpublish_log(t('Roles, permissions and configuration settings are in place'));
}

/**
 * Setup 3 custom menus and primary links.
 */
function _openpublish_modify_menus() {
  cache_clear_all();
  menu_rebuild();
  
  $op_plid = install_menu_create_menu_item('admin/settings/openpublish/api-keys', 'OpenPublish Control Panel', 'Short cuts to important functionality.', 'navigation', 1, -49);
  install_menu_create_menu_item('admin/settings/openpublish/api-keys', 'API Keys', 'Calais, Apture and Flickr API keys.', 'navigation', $op_plid, 1);
  install_menu_create_menu_item('admin/settings/openpublish/calais-suite', 'Calais Suite', 'Administrative links to Calais, More Like This and Topic Hubs functionality.', 'navigation', $op_plid, 2);
  install_menu_create_menu_item('admin/settings/openpublish/content', 'Content Links', 'Administrative links to content, comment, feed and taxonomy management.', 'navigation', $op_plid, 3);

  install_menu_create_menu('Footer Primary', 'footer-primary');
  install_menu_create_menu('Footer Secondary', 'footer-secondary');
  install_menu_create_menu('Top Menu', 'top-menu'); 
  
  $top_menu = array (
    array (
	  'menu' => 'menu-top-menu',
	  'title' => 'About Us',
	  'path' => 'node/1',
	  'weight' => 1
	),
	array (
	  'menu' => 'menu-top-menu',
	  'title' => 'Advertise',
	  'path' => 'node/2',
	  'weight' => 2
	),
	array (
	  'menu' => 'menu-top-menu',
	  'title' => 'Subscribe',
	  'path' => 'node/3',
	  'weight' => 3
	),
	array (
	  'menu' => 'menu-top-menu',
	  'title' => 'RSS',
	  'path' => 'node/4',
	  'weight' => 4
	),		
  );
  
  $footer_secondary_menu = array (
    array(
      'menu' => 'menu-footer-secondary',
	  'title' => 'Subscribe',
	  'path' => 'node/3',
	  'weight' => 1,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'Advertise',
	  'path' => 'node/2',
	  'weight' => 2,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'Jobs',
	  'path' => 'node/5',
	  'weight' => 4,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'Store',
	  'path' => 'node/6',
	  'weight' => 5,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'About Us',
	  'path' => 'node/1',
	  'weight' => 6,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'Site Map',
	  'path' => 'node/7',
	  'weight' => 7,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'Terms of Use',
	  'path' => 'node/8',
	  'weight' => 8,
	),
	array(
	  'menu' => 'menu-footer-secondary',
	  'title' => 'Privacy Policy',
	  'path' => 'node/9',
	  'weight' => 9,
	),
  );
  
  $footer_primary_menu = array(
    array(
      'menu' => 'menu-footer-primary',
	  'title' => 'Latest News',
	  'path' => 'articles/all',
	  'weight' => 1,
	),
	array(
	  'menu' => 'menu-footer-primary',
	  'title' => 'Hot Topics',
	  'path' => 'popular/all',
	  'weight' => 2,
	),
	array(
	  'menu' => 'menu-footer-primary',
	  'title' => 'Blogs',
	  'path' => 'blogs',
	  'weight' => 3,
	),
	array(
	  'menu' => 'menu-footer-primary',
	  'title' => 'Resources',
	  'path' => 'resources',
	  'weight' => 4,
	),
	array(
	  'menu' => 'menu-footer-primary',
	  'title' => 'Events',
	  'path' => 'events',
	  'weight' => 5,
	),
  );
  
  $primary_links = array(
    array(
      'menu' => 'primary-links',
	  'title' => 'Home',
	  'path' => '<front>',
	  'weight' => 1,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Business',
	  'path' => 'articles/Business',
	  'weight' => 2,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Health',
	  'path' => 'articles/Health',
	  'weight' => 3,
	),	
	array(
      'menu' => 'primary-links',
	  'title' => 'Politics',
	  'path' => 'articles/Politics',
	  'weight' => 4,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Technology',
	  'path' => 'articles/Technology',
	  'weight' => 5,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Blogs',
	  'path' => 'blogs',
	  'weight' => 6,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Resources',
	  'path' => 'resources',
	  'weight' => 7,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Events',
	  'path' => 'events',
	  'weight' => 8,
	),
	array(
      'menu' => 'primary-links',
	  'title' => 'Topic Hubs',
	  'path' => 'topic-hubs',
	  'weight' => 9,
	),
  );  
 
  foreach ($primary_links as $item) {	
    install_menu_create_menu_item($item[path], $item[title], '', $item[menu], 0, $item[weight]);
  }

  foreach ($footer_primary_menu as $item) {	
    install_menu_create_menu_item($item[path], $item[title], '', $item[menu], 0, $item[weight]);
  }

  foreach ($top_menu as $item) {	
    install_menu_create_menu_item($item[path], $item[title], '', $item[menu], 0, $item[weight]);
  }
  
  foreach ($footer_secondary_menu as $item) {	
    install_menu_create_menu_item($item[path], $item[title], '', $item[menu], 0, $item[weight]);
  }
  _openpublish_log(t('Menus created and configured'));
} 

/**
 * Set views as "default views" so they can be reverted
 */
function _openpublish_set_views() {
  views_include_default_views();
  
  //popular view is disabled by default, enable it
  $view = views_get_view('popular');
  $view->disabled = FALSE;
  $view->save();
  
  _openpublish_log(t('Views configuration updated')); 
} 


/**
 * Create custom blocks and set region and pages
 */
function _openpublish_setup_blocks() {
  cache_clear_all();
  
  //needs to set or blocks from modules get wrong region
  global $theme_key; 
  $theme_key = 'openpublish';

  // install the five manual blocks create through the UI
  install_create_custom_block('Powered by: <a href="http://www.phase2technology.com/" target="_blank">Phase2 Technology</a>', 'Powered by Phase2', 1);
  install_create_custom_block('<?php 
  //placeholder ad
  print theme("image", "sites/all/themes/openpublish/images/placeholder_ad_banner.gif"); ?><div class="clear"></div>', 'Top Banner Ad', 3);
  install_create_custom_block('<p><?php 
  //placeholder ad
  print theme("image", "sites/all/themes/openpublish/images/placeholder_ad_rectangle.gif"); ?></p>', 'Right Block Square Ad', 3);
  install_create_custom_block('<p><?php 
  //placeholder ad
  print theme("image", "sites/all/themes/openpublish/images/placeholder_ad_rectangle.gif"); ?></p>', 'Homepage Ad Block 1', 3);
  install_create_custom_block('<p><?php 
  //placeholder ad
  print theme("image", "sites/all/themes/openpublish/images/placeholder_ad_rectangle.gif"); ?></p>', 'Homepage Ad Block 2', 3);
   
  // put the above newly created in the blocks table
  _block_rehash();
 
  install_set_block('views', 'blogs-block_2', 'openpublish', 'homepage_center', -10);
  install_set_block('views', 'multimedia-block_1', 'openpublish', 'homepage_center', -9);
  install_set_block('views', 'resources-block_1', 'openpublish', 'homepage_center', -8);
  install_set_block('views', 'twitter_items-block_1', 'openpublish', 'homepage_center', -7);
  install_set_block('views', 'events-block_1', 'openpublish', 'homepage_center', -6);
  install_set_block('views', 'articles-block_2', 'openpublish', 'homepage_left', -10);
  install_set_block('views', 'articles-block_1', 'openpublish', 'homepage_left', -9);
  install_set_block('views', 'feed_items-block_1', 'openpublish', 'homepage_left', -8);
  install_set_block('views', 'most_viewed_by_taxonomy-block', 'openpublish', 'right', -7);
  install_set_block('views', 'most_viewed_by_node_type-block', 'openpublish', 'right', -6);
  install_set_block('views', 'most_viewed_multimedia-block', 'openpublish', 'right', -5);
  install_set_block('views', 'most_commented_articles-block_1', 'openpublish', 'right', -4);
  install_set_block('views', 'most_commented_blogs-block_1', 'openpublish', 'right', -3);
  
  install_set_block('morelikethis', 'googlevideo', 'openpublish', 'content', -10); 	  
  install_set_block('block', '1', 'openpublish', 'footer',  - 2);
  install_set_block('block', '2', 'openpublish', 'header', -10);
  install_set_block('block', '4', 'openpublish', 'homepage_right', -10);
  install_set_block('popular_terms', '0', 'openpublish', 'homepage_right', -9);
  install_set_block('block', '5', 'openpublish', 'homepage_right', -8);  
  install_set_block('popular_terms', '1', 'openpublish', 'homepage_right', -7);
  install_set_block('morelikethis', 'taxonomy', 'openpublish', 'right', -10);
  install_set_block('morelikethis', 'flickr', 'openpublish', 'right', -9);
  install_set_block('block', '3', 'openpublish', 'right', -8);
  //install_set_block('openpublish_administration', '0', 'openpublish', 'left', 0);
 
  db_query("UPDATE {blocks} SET title = '%s' WHERE module = '%s' AND delta = '%s' AND theme= '%s'", 'Google Videos Like This', 'morelikethis', 'taxonomy', 'openpublish');
  db_query("UPDATE {blocks} SET title = '%s' WHERE module = '%s' AND delta = '%s' AND theme= '%s'", 'Flickr Images Like This', 'morelikethis', 'flickr', 'openpublish');
  db_query("UPDATE {blocks} SET title = '%s' WHERE module = '%s' AND delta = '%s' AND theme= '%s'", 'Recommended Reading', 'morelikethis', 'taxonomy', 'openpublish'); 
  db_query("UPDATE {blocks} SET title = '%s' WHERE module = '%s' AND delta = '%s' AND theme= '%s'", 'Most Used Terms', 'popular_terms', '0', 'openpublish');
  db_query("UPDATE {blocks} SET title = '%s' WHERE module = '%s' AND delta = '%s' AND theme= '%s'", 'Featured Topic Hubs', 'popular_terms', '1', 'openpublish');
  
  db_query("UPDATE {blocks} SET region = '%s', status = 1, weight = %d WHERE module = '%s' AND delta = '%s' AND theme = '%s'", $region, $weight, $module, $delta, $theme);
 
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'article/*
blog/*
resource/*
event/*', 'morelikethis', 'googlevideo', 'openpublish');  
 
  db_query("UPDATE {blocks} SET pages = '%s', weight = -20 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'admin*
topic-hub/*
package/*', 'block', '3', 'openpublish');
 
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'article/*
blog/*
resource/*
event/*', 'morelikethis', 'flickr', 'openpublish');
 
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'article/*
blog/*
resource/*
event/*', 'morelikethis', 'taxonomy ', 'openpublish');

  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'articles/*', 'views', 'most_commented_articles-block_1', 'openpublish');
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'blogs', 'views', 'most_commented_blogs-block_1', 'openpublish');
 
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'resources*
events*
blogs*', 'views', 'most_viewed_by_node_type-block', 'openpublish');
 
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'articles*', 'views', 'most_viewed_by_taxonomy-block', 'openpublish');
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'multimedia', 'views', 'most_viewed_multimedia-block', 'openpublish'); 

 
  db_query("UPDATE {blocks} SET pages = '%s', visibility = 1 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'admin
admin/*', 'openpublish_administration', '0', 'openpublish');
  
  install_add_block_role('openpublish_administration', '0', install_get_rid('administrator'));
  install_add_block_role('openpublish_administration', '0', install_get_rid('editor'));
  install_add_block_role('openpublish_administration', '0', install_get_rid('author'));
  install_add_block_role('openpublish_administration', '0', install_get_rid('web editor'));
 
  db_query("UPDATE {blocks} SET status = 0 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'user', '0', 'openpublish');
  db_query("UPDATE {blocks} SET status = 0 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'user', '1', 'openpublish');
  db_query("UPDATE {blocks} SET status = 0 WHERE module = '%s' AND delta = '%s' AND theme = '%s'", 'system', '0', 'openpublish');
  
  _openpublish_log(t('Blocks initialized and configured'));
}

function _openpublish_log($msg) {
  error_log($msg);
  drupal_set_message($msg);
}
