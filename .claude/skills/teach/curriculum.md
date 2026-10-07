# Curriculum — skill tree

This is a menu, not a railroad. Each node lists its prereqs (→), an exercise, and a "done when". Prefer exercises that feed the game's effect palette. Node IDs (`M1`, `G3`…) are what the profile's skill map refers to.

---

## E — Engine foundations (Odin)

- **E1 Frame loop + timing**: QueryPerformanceCounter, dt, why `pos += v` without dt is a bug. *Done when:* a dot moves at the same speed at 30 and 300 fps.
- **E2 Fixed timestep** → E1. Accumulator loop, interpolation between sim states (Glenn Fiedler, "Fix Your Timestep!"). *Done when:* the sim runs at 120 Hz regardless of render rate and has no jitter.
- **E3 Memory**: arenas, temp allocator per frame, no per-frame heap allocations. *Done when:* the frame loop does 0 allocations (verify with a tracking allocator).
- **E4 Hot reload** → E1. Game as a DLL, state in the host (Karl Zylinski pattern). *Done when:* you can tweak a spin speed constant without restarting.
- **E5 Data layout**: AoS vs SoA, cache lines, why 1M particles want `[]f32` per field. *Done when:* you benchmark both on 1M particles and explain the difference.
- **E6 Profiling**: timestamps, a tiny scope-timer, GPU timestamp queries later. *Done when:* the frame time is shown on screen, split into CPU sim, upload and GPU.

## M — Math

- **M1 Vectors**: add, scale, length, normalize, dot (projection, angle), cross (perpendicular, handedness). *Exercise:* a particle that steers toward the mouse. *Done when:* you can explain dot as a "how aligned" number.
- **M2 Unit circle, sin/cos** → M1. Angle → (cos θ, sin θ). Radians, why 2π. Phase, frequency, amplitude: `A·sin(2πft + φ)`. *Exercise:* N particles evenly on a ring (`θ_i = 2π·i/N`) spinning at ω rad/s. *Stretch:* two rings counter-rotating (ω and −ω), a ring whose radius pulses with `r = r0 + a·sin(t)`, and a Lissajous figure.
- **M3 Parametric curves** → M2. Helix `(r cos t, r sin t, k t)`, spiral, torus knot `(p,q)`, rose curves. *Exercise:* particles flowing along a helix: each has `t_i += speed·dt` and wraps. *This is the vein/blood-flow primitive.*
- **M4 Rotation in 2D and 3D** → M2. The 2D rotation matrix and its derivation from M2. Rotating around an arbitrary centre (translate → rotate → translate back). Axis-angle and Rodrigues' formula. *Exercise:* a ring spinning around its own centre while that centre orbits another point (moon-around-planet).
- **M5 Matrices + coordinate spaces** → M4. Local → world → view → clip. Column vs row major (Odin's `matrix` type), why order matters. *Done when:* a ring is rotated in its own local frame and placed anywhere in the world.
- **M6 Quaternions** → M4. Why Euler angles gimbal-lock, quaternion multiply, slerp. *Exercise:* a smooth camera orbit and tumbling ring orientations with no flips.
- **M7 Interpolation + easing**: lerp, smoothstep, easing curves, exponential decay `x += (target−x)·(1−e^(−k·dt))` (framerate-independent!). *Exercise:* slow-down/speed-up of a spin that feels good.
- **M8 Splines** → M3, M7. Catmull-Rom and Bézier, arc-length parametrization (why constant `t` speed isn't constant speed). *Exercise:* blood particles moving at constant speed along a hand-placed vein spline.
- **M9 Noise**: value, Perlin and simplex noise, fBm, curl noise (divergence-free → swirly flow with no sinks). *Exercise:* space dust drifting in a curl field.
- **M10 Random distributions**: uniform on a disc (why `r = sqrt(u)`), on a sphere surface, inside a sphere, blue noise / Poisson disc. *Done when:* a sphere of particles has no clumping at the poles.

## P — Physics / simulation

- **P1 Integration** → E1, M1. Explicit Euler, semi-implicit Euler, Verlet. Energy drift. *Exercise:* an orbit that does or doesn't spiral out depending on the integrator.
- **P2 Forces**: gravity, drag, point attractors, inverse-square, damping. *Exercise:* a **waterfall emitter**: spawn at the lip, gravity plus slight noise, lifetime, respawn. Ring buffer for the particle pool.
- **P3 Springs** → P1. Hooke's law plus damping, critically damped springs (great for game feel). *Exercise:* particles springing back to a shape after an explosion.
- **P4 Particle systems as data**: emitters, lifetime, per-particle attributes, color/size over life. Pool with swap-remove or a ring buffer. *Done when:* 100k particles with spawn and death and 0 allocs.
- **P5 Shape targets / morphing** → M10, P3. Particles that seek target positions sampled from a shape. Morph ring → sphere → heart. *This is the core of the palette.*
- **P6 Flow along paths** → M8. Blood/energy particles advected along splines, with color by `t` (blue → red), pulsing speed driven by a heartbeat curve.
- **P7 Periodic deformation**: heartbeat (an asymmetric pulse curve, not a pure sine), breathing lungs (scale a volume with a slow ease-in-out). *Exercise:* the "transparent body" demo scene.
- **P8 Waves** → M2. 1D string wave equation, sum-of-sines water, Gerstner waves (particles move in circles, which makes crests sharp), 2D height-field wave sim. *Exercise:* an ocean surface made of a particle grid.
- **P9 Collisions**: particle vs plane/sphere/SDF, restitution, spatial hashing for particle–particle interactions.
- **P10 Flocking / boids** → P9. Separation, alignment, cohesion. *Exercise:* an enemy swarm.

## G — GPU / Vulkan / shaders

Rule: the math nodes come first on the CPU. G nodes move proven sims to the GPU.

- **G1 How a GPU draws**: vertices → raster → fragments, why the GPU is a throughput machine, what a draw call costs.
- **G2 Vulkan bring-up** → G1. Instance, device, queue, swapchain, command buffers, sync (fences and semaphores), Vulkan 1.3 dynamic rendering. *Boss level*: lots of ceremony. Boilerplate may be delegated; understanding the frame-in-flight sync may not. *Done when:* a cleared screen, resizable, validation layers silent.
- **G3 Buffers + uploading particles** → G2, P4. Staging vs host-visible memory, a per-frame upload ring. *Done when:* the CPU sim's particles are on screen.
- **G4 First shaders (Slang)** → G3. Vertex shader expanding instanced quads to camera-facing billboards; fragment shader drawing an **analytically anti-aliased circle** via `smoothstep` on distance. That's the "clean, easy to tell apart" particle. *Done when:* crisp round particles at any size, no jaggies.
- **G5 Blending**: alpha vs additive vs premultiplied, why additive needs no sorting, depth test vs depth write for particles.
- **G6 Compute shaders** → G4, P4. Move the sim to the GPU: storage buffers, dispatch sizes, barriers between compute and draw. *Done when:* 1M+ particles at 144+ fps (measure it).
- **G7 GPU particle lifecycle** → G6. Spawn and kill on the GPU, atomic counters, indirect draw.
- **G8 Post-processing**: HDR target, bloom (downsample/upsample chain), tonemapping, vignette, grain. Glow sells the vibe.
- **G9 Debugging**: RenderDoc captures, validation layers, reading a GPU timeline.

## A — Audio

- **A1 Sampling basics**: sample rate, Nyquist, PCM, the audio callback (miniaudio), why you never allocate or lock in it.
- **A2 Oscillators** → M2, A1. Sine, saw, square, triangle from phase accumulation (`phase += f/sr`). Aliasing in naive saw/square (→ polyBLEP later). *Done when:* you play a clean 440 Hz sine with no clicks.
- **A3 Envelopes + mixing**: ADSR, gain staging, clipping, why clicks happen (discontinuities).
- **A4 Filters**: one-pole low-pass, biquad (RBJ cookbook). *Exercise:* a filter sweep on a saw: instant techno.
- **A5 Synth voice + sequencer** → A2–A4. A kick drum (sine with a pitch envelope), hats (filtered noise), a 16-step sequencer.
- **A6 DFT → FFT** → M2, A1. The DFT as correlation with sinusoids, then why radix-2 FFT is O(N log N). Write it. Windowing (Hann), bins → Hz.
- **A7 Audio reactivity** → A6. Log-spaced bands, attack/release smoothing, spectral-flux onset (kick) detection, driving particle params. Thread-safe handoff from the audio thread to the game thread.

## Palette / tooling track (the "drag-drop effects" dream)

Do this incrementally once the M2–M4 and P4–P5 nodes are solid:
1. **Shapes as functions**: `ring(i, n) -> pos`, `sphere`, `helix`, `torus`, `grid`. Pure functions, easy to test.
2. **Modifiers as data**: spin(axis, speed), orbit, pulse(curve), follow(spline), color_over(t). An effect is a small array of modifiers applied in order. No class hierarchy.
3. **Composites**: "heart" = a shape + a pulse(heartbeat) + vein splines with flow. It's data, so it's reusable and can be hot-reloaded.
4. **Live tweaking**: hot reload first, then a tiny immediate-mode debug UI (sliders), then save and load effects to a text file.
5. **Editor**: drag-drop comes last, once the data format has stopped changing.
