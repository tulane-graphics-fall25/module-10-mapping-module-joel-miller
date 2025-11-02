#version 150

uniform vec4 ambient;
uniform vec4 LightPosition;

in vec4 pos;
in vec4 N;
in vec2 texCoord;

uniform mat4 ModelViewLight;

uniform sampler2D textureEarth;
uniform sampler2D textureNight;
uniform sampler2D textureCloud;
uniform sampler2D texturePerlin;

uniform float animate_time;


out vec4 fragColor;

void main()
{
 // Eye-space vectors
  vec3 Ln = normalize((ModelViewLight * LightPosition - pos).xyz);
  vec3 Nn = normalize(N.xyz);
  vec3 Vn = normalize(-pos.xyz);

  // Daylight strength (Lambert)
  float lambert = max(dot(Nn, Ln), 0.0);

  // Twilight mix factor: 0 in day, ~1 at night (smooth transition)
  float nightFactor = smoothstep(0.55, 0.10, lambert);

  // Base textures
  vec3 day   = texture(textureEarth, texCoord).rgb;
  vec3 night = texture(textureNight, texCoord).rgb;
  float cloud = texture(textureCloud, texCoord).r;  // grayscale cloud opacity (0..1)

  // --- Cloud model ---
  // Day: clouds brighten a bit, but also occlude the surface
  const float cloudBright   = 0.60;  // add white from clouds
  const float cloudOccludeD = 0.35;  // dim the day albedo under clouds
  day = clamp(day * (1.0 - cloudOccludeD * cloud) + cloudBright * cloud, 0.0, 1.0);

  // Night: clouds dim city lights beneath them
  const float cloudOccludeN = 0.50;
  night *= (1.0 - cloudOccludeN * cloud);

  // Optional contrast/boost for night lights
  night *= 1.1;
  night = pow(max(night, 0.0), vec3(0.8));

  // Faint "moonlit" clouds visible on the night side
  vec3 moonTint = vec3(0.75, 0.80, 1.0);
  vec3 cloudsNight = moonTint * (0.15 * cloud) * nightFactor;

  // Compose final color
  vec3 color = ambient.rgb                // ambient base
             + day * lambert             // sunlit surface
             + night * nightFactor       // city lights at night
             + cloudsNight;              // faint clouds at night

  color = clamp(color, 0.0, 1.0);
  fragColor = vec4(color, 1.0);
}

