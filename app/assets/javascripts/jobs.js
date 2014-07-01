$(document).ready(function() {
  $("#job_type").bind("change", function() {
    if (this.value == "CronJob") {
      $(".cronjob").show();
      $(".intervaljob").hide();
    } else {
      $(".cronjob").hide();
      $(".intervaljob").show();
    }
  });
  $("#job_type").change();
});