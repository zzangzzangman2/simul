/* Flutter replaces the following template expressions during web builds. */
/* eslint-disable @typescript-eslint/no-unused-expressions */
{{flutter_js}}

{{flutter_build_config}}

_flutter.loader.load({
  config: {
    hostElement: document.getElementById('flutter_host'),
  },
});
