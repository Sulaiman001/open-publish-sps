api = 2
core = 7.0
projects[drupal][type] = core
projects[drupal][patch][] = http://drupal.org/files/issues/object_conversion_menu_router_build-972536-1.patch
projects[drupal][patch][] = http://drupal.org/files/issues/992540-3-reset_flood_limit_on_password_reset-drush.patch

projects[openpublish][type] = profile
projects[openpublish][download][type] = git
projects[openpublish][download][url] = git@phase2.beanstalkapp.com:/openpublish3-alpha.git