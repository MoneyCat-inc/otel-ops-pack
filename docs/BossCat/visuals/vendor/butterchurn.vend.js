var butterchurn = (() => {
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };

  // node_modules/butterchurn/lib/butterchurn.min.js
  var require_butterchurn_min = __commonJS({
    "node_modules/butterchurn/lib/butterchurn.min.js"(exports, module) {
      !(function(t, e) {
        "object" == typeof exports && "object" == typeof module ? module.exports = e() : "function" == typeof define && define.amd ? define("butterchurn", [], e) : "object" == typeof exports ? exports.butterchurn = e() : t.butterchurn = e();
      })(window, function() {
        return (function(t) {
          var e = {};
          function i(s) {
            if (e[s]) return e[s].exports;
            var r = e[s] = { i: s, l: false, exports: {} };
            return t[s].call(r.exports, r, r.exports, i), r.l = true, r.exports;
          }
          return i.m = t, i.c = e, i.d = function(t2, e2, s) {
            i.o(t2, e2) || Object.defineProperty(t2, e2, { enumerable: true, get: s });
          }, i.r = function(t2) {
            "undefined" != typeof Symbol && Symbol.toStringTag && Object.defineProperty(t2, Symbol.toStringTag, { value: "Module" }), Object.defineProperty(t2, "__esModule", { value: true });
          }, i.t = function(t2, e2) {
            if (1 & e2 && (t2 = i(t2)), 8 & e2) return t2;
            if (4 & e2 && "object" == typeof t2 && t2 && t2.__esModule) return t2;
            var s = /* @__PURE__ */ Object.create(null);
            if (i.r(s), Object.defineProperty(s, "default", { enumerable: true, value: t2 }), 2 & e2 && "string" != typeof t2) for (var r in t2) i.d(s, r, function(e3) {
              return t2[e3];
            }.bind(null, r));
            return s;
          }, i.n = function(t2) {
            var e2 = t2 && t2.__esModule ? function() {
              return t2.default;
            } : function() {
              return t2;
            };
            return i.d(e2, "a", e2), e2;
          }, i.o = function(t2, e2) {
            return Object.prototype.hasOwnProperty.call(t2, e2);
          }, i.p = "", i(i.s = 5);
        })([function(t, e, i) {
          var s;
          void 0 === (s = function() {
            return { baseVals: { gammaadj: 1.25, wave_g: 0.5, mv_x: 12, warpscale: 1, brighten: 0, mv_y: 9, wave_scale: 1, echo_alpha: 0, additivewave: 0, sx: 1, sy: 1, warp: 0.01, red_blue: 0, wave_mode: 0, wave_brighten: 0, wrap: 0, zoomexp: 1, fshader: 0, wave_r: 0.5, echo_zoom: 1, wave_smoothing: 0.75, warpanimspeed: 1, wave_dots: 0, wave_x: 0.5, wave_y: 0.5, zoom: 1, solarize: 0, modwavealphabyvolume: 0, dx: 0, cx: 0.5, dy: 0, darken_center: 0, cy: 0.5, invert: 0, bmotionvectorson: 0, rot: 0, modwavealphaend: 0.95, wave_mystery: -0.2, decay: 0.9, wave_a: 1, wave_b: 0.5, rating: 5, modwavealphastart: 0.75, darken: 0, echo_orient: 0, ib_r: 0.5, ib_g: 0.5, ib_b: 0.5, ib_a: 0, ib_size: 0, ob_r: 0.5, ob_g: 0.5, ob_b: 0.5, ob_a: 0, ob_size: 0, mv_dx: 0, mv_dy: 0, mv_a: 0, mv_r: 0.5, mv_g: 0.5, mv_b: 0.5, mv_l: 0 }, init_eqs: function() {
              return {};
            }, frame_eqs: function(t2) {
              return t2.rkeys = ["warp"], t2.zoom = 1.01 + 0.02 * t2.treb_att, t2.warp = 0.15 + 0.25 * t2.bass_att, t2;
            }, pixel_eqs: function(t2) {
              return t2.warp = t2.warp + 0.15 * t2.rad, t2;
            }, waves: [{ baseVals: { a: 1, enabled: 0, b: 1, g: 1, scaling: 1, samples: 512, additive: 0, usedots: 0, spectrum: 0, r: 1, smoothing: 0.5, thick: 0, sep: 0 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            }, point_eqs: "" }, { baseVals: { a: 1, enabled: 0, b: 1, g: 1, scaling: 1, samples: 512, additive: 0, usedots: 0, spectrum: 0, r: 1, smoothing: 0.5, thick: 0, sep: 0 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            }, point_eqs: "" }, { baseVals: { a: 1, enabled: 0, b: 1, g: 1, scaling: 1, samples: 512, additive: 0, usedots: 0, spectrum: 0, r: 1, smoothing: 0.5, thick: 0, sep: 0 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            }, point_eqs: "" }, { baseVals: { a: 1, enabled: 0, b: 1, g: 1, scaling: 1, samples: 512, additive: 0, usedots: 0, spectrum: 0, r: 1, smoothing: 0.5, thick: 0, sep: 0 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            }, point_eqs: "" }], shapes: [{ baseVals: { r2: 0, a: 1, enabled: 0, b: 0, tex_ang: 0, thickoutline: 0, g: 0, textured: 0, g2: 1, tex_zoom: 1, additive: 0, border_a: 0.1, border_b: 1, b2: 0, a2: 0, r: 1, border_g: 1, rad: 0.1, x: 0.5, y: 0.5, ang: 0, sides: 4, border_r: 1 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            } }, { baseVals: { r2: 0, a: 1, enabled: 0, b: 0, tex_ang: 0, thickoutline: 0, g: 0, textured: 0, g2: 1, tex_zoom: 1, additive: 0, border_a: 0.1, border_b: 1, b2: 0, a2: 0, r: 1, border_g: 1, rad: 0.1, x: 0.5, y: 0.5, ang: 0, sides: 4, border_r: 1 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            } }, { baseVals: { r2: 0, a: 1, enabled: 0, b: 0, tex_ang: 0, thickoutline: 0, g: 0, textured: 0, g2: 1, tex_zoom: 1, additive: 0, border_a: 0.1, border_b: 1, b2: 0, a2: 0, r: 1, border_g: 1, rad: 0.1, x: 0.5, y: 0.5, ang: 0, sides: 4, border_r: 1 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            } }, { baseVals: { r2: 0, a: 1, enabled: 0, b: 0, tex_ang: 0, thickoutline: 0, g: 0, textured: 0, g2: 1, tex_zoom: 1, additive: 0, border_a: 0.1, border_b: 1, b2: 0, a2: 0, r: 1, border_g: 1, rad: 0.1, x: 0.5, y: 0.5, ang: 0, sides: 4, border_r: 1 }, init_eqs: function(t2) {
              return t2.rkeys = [], t2;
            }, frame_eqs: function(t2) {
              return t2;
            } }], warp: "shader_body {\nret = texture2D(sampler_main, uv).rgb;\nret -= 0.004;\n}\n", comp: "shader_body {\nret = texture2D(sampler_main, uv).rgb;\nret *= hue_shader;\n}\n" };
          }.apply(e, [])) || (t.exports = s);
        }, function(t, e, i) {
          "use strict";
          {
            const t2 = (t3, e3) => {
              var i2 = "function" == typeof e3, s = "function" == typeof e3, r = "function" == typeof e3;
              Object.defineProperty(Math, t3, { configurable: i2, enumerable: r, writable: s, value: e3 });
            };
            t2("DEG_PER_RAD", Math.PI / 180), t2("RAD_PER_DEG", 180 / Math.PI);
            const e2 = new Float32Array(1);
            t2("scale", function(t3, e3, i2, s, r) {
              return 0 === arguments.length ? NaN : Number.isNaN(t3) || Number.isNaN(e3) || Number.isNaN(i2) || Number.isNaN(s) || Number.isNaN(r) ? NaN : t3 === 1 / 0 || t3 === -1 / 0 ? t3 : (t3 - e3) * (r - s) / (i2 - e3) + s;
            }), t2("fscale", function(t3, i2, s, r, a) {
              return e2[0] = Math.scale(t3, i2, s, r, a), e2[0];
            }), t2("clamp", function(t3, e3, i2) {
              return Math.min(i2, Math.max(e3, t3));
            }), t2("radians", function(t3) {
              return t3 * Math.DEG_PER_RAD;
            }), t2("degrees", function(t3) {
              return t3 * Math.RAD_PER_DEG;
            });
          }
        }, function(t, e) {
          window.sqr = function(t2) {
            return t2 * t2;
          }, window.sqrt = function(t2) {
            return Math.sqrt(Math.abs(t2));
          }, window.log10 = function(t2) {
            return Math.log(t2) * Math.LOG10E;
          }, window.sign = function(t2) {
            return t2 > 0 ? 1 : t2 < 0 ? -1 : 0;
          }, window.rand = function(t2) {
            var e2 = Math.floor(t2);
            return e2 < 1 ? Math.random() : Math.random() * e2;
          }, window.randint = function(t2) {
            return Math.floor(rand(t2));
          }, window.bnot = function(t2) {
            return Math.abs(t2) < 1e-5 ? 1 : 0;
          }, window.pow = function(t2, e2) {
            var i, s = Math.pow(t2, e2);
            return i = s, !isFinite(i) || isNaN(i) ? 0 : s;
          }, window.div = function(t2, e2) {
            return 0 === e2 ? 0 : t2 / e2;
          }, window.mod = function(t2, e2) {
            return 0 === e2 ? 0 : Math.floor(t2) % Math.floor(e2);
          }, window.bitor = function(t2, e2) {
            return Math.floor(t2) | Math.floor(e2);
          }, window.bitand = function(t2, e2) {
            return Math.floor(t2) & Math.floor(e2);
          }, window.sigmoid = function(t2, e2) {
            var i = 1 + Math.exp(-t2 * e2);
            return Math.abs(i) > 1e-5 ? 1 / i : 0;
          }, window.bor = function(t2, e2) {
            return Math.abs(t2) > 1e-5 || Math.abs(e2) > 1e-5 ? 1 : 0;
          }, window.band = function(t2, e2) {
            return Math.abs(t2) > 1e-5 && Math.abs(e2) > 1e-5 ? 1 : 0;
          }, window.equal = function(t2, e2) {
            return Math.abs(t2 - e2) < 1e-5 ? 1 : 0;
          }, window.above = function(t2, e2) {
            return t2 > e2 ? 1 : 0;
          }, window.below = function(t2, e2) {
            return t2 < e2 ? 1 : 0;
          }, window.ifcond = function(t2, e2, i) {
            return Math.abs(t2) > 1e-5 ? e2 : i;
          }, window.memcpy = function(t2, e2, i, s) {
            var r = e2, a = i, h = s;
            return a < 0 && (h += a, r -= a, a = 0), r < 0 && (h += r, a -= r, r = 0), h > 0 && t2.copyWithin(r, a, h), e2;
          };
        }, , , function(t, e, i) {
          "use strict";
          i.r(e);
          i(1), i(2);
          function s(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var r = (function() {
            function t2(e3, i3) {
              var s2 = arguments.length > 2 && void 0 !== arguments[2] && arguments[2];
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.samplesIn = e3, this.samplesOut = i3, this.equalize = s2, this.NFREQ = 2 * i3, this.equalize && this.initEqualizeTable(), this.initBitRevTable(), this.initCosSinTable();
            }
            var e2, i2, r2;
            return e2 = t2, (i2 = [{ key: "initEqualizeTable", value: function() {
              this.equalizeArr = new Float32Array(this.samplesOut);
              for (var t3 = 1 / this.samplesOut, e3 = 0; e3 < this.samplesOut; e3++) this.equalizeArr[e3] = -0.02 * Math.log((this.samplesOut - e3) * t3);
            } }, { key: "initBitRevTable", value: function() {
              this.bitrevtable = new Uint16Array(this.NFREQ);
              for (var t3 = 0; t3 < this.NFREQ; t3++) this.bitrevtable[t3] = t3;
              for (var e3 = 0, i3 = 0; i3 < this.NFREQ; i3++) {
                if (e3 > i3) {
                  var s2 = this.bitrevtable[i3];
                  this.bitrevtable[i3] = this.bitrevtable[e3], this.bitrevtable[e3] = s2;
                }
                for (var r3 = this.NFREQ >> 1; r3 >= 1 && e3 >= r3; ) e3 -= r3, r3 >>= 1;
                e3 += r3;
              }
            } }, { key: "initCosSinTable", value: function() {
              for (var t3 = 2, e3 = 0; t3 <= this.NFREQ; ) e3 += 1, t3 <<= 1;
              this.cossintable = [new Float32Array(e3), new Float32Array(e3)], t3 = 2;
              for (var i3 = 0; t3 <= this.NFREQ; ) {
                var s2 = -2 * Math.PI / t3;
                this.cossintable[0][i3] = Math.cos(s2), this.cossintable[1][i3] = Math.sin(s2), i3 += 1, t3 <<= 1;
              }
            } }, { key: "timeToFrequencyDomain", value: function(t3) {
              for (var e3 = new Float32Array(this.NFREQ), i3 = new Float32Array(this.NFREQ), s2 = 0; s2 < this.NFREQ; s2++) {
                var r3 = this.bitrevtable[s2];
                r3 < this.samplesIn ? e3[s2] = t3[r3] : e3[s2] = 0, i3[s2] = 0;
              }
              for (var a2 = 2, h2 = 0; a2 <= this.NFREQ; ) {
                for (var o2 = this.cossintable[0][h2], n2 = this.cossintable[1][h2], l2 = 1, m2 = 0, u2 = a2 >> 1, g2 = 0; g2 < u2; g2++) {
                  for (var c2 = g2; c2 < this.NFREQ; c2 += a2) {
                    var A2 = c2 + u2, f2 = l2 * e3[A2] - m2 * i3[A2], d2 = l2 * i3[A2] + m2 * e3[A2];
                    e3[A2] = e3[c2] - f2, i3[A2] = i3[c2] - d2, e3[c2] += f2, i3[c2] += d2;
                  }
                  var v2 = l2;
                  l2 = v2 * o2 - m2 * n2, m2 = m2 * o2 + v2 * n2;
                }
                a2 <<= 1, h2 += 1;
              }
              var p2 = new Float32Array(this.samplesOut);
              if (this.equalize) for (var _2 = 0; _2 < this.samplesOut; _2++) p2[_2] = this.equalizeArr[_2] * Math.sqrt(e3[_2] * e3[_2] + i3[_2] * i3[_2]);
              else for (var x2 = 0; x2 < this.samplesOut; x2++) p2[x2] = Math.sqrt(e3[x2] * e3[x2] + i3[x2] * i3[x2]);
              return p2;
            } }]) && s(e2.prototype, i2), r2 && s(e2, r2), t2;
          })();
          function a(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var h = (function() {
            function t2(e3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.numSamps = 512, this.fftSize = 2 * this.numSamps, this.fft = new r(this.fftSize, 512, true), e3 && (this.audioContext = e3, this.audible = e3.createDelay(), this.analyser = e3.createAnalyser(), this.analyser.smoothingTimeConstant = 0, this.analyser.fftSize = this.fftSize, this.audible.connect(this.analyser), this.analyserL = e3.createAnalyser(), this.analyserL.smoothingTimeConstant = 0, this.analyserL.fftSize = this.fftSize, this.analyserR = e3.createAnalyser(), this.analyserR.smoothingTimeConstant = 0, this.analyserR.fftSize = this.fftSize, this.splitter = e3.createChannelSplitter(2), this.audible.connect(this.splitter), this.splitter.connect(this.analyserL, 0), this.splitter.connect(this.analyserR, 1)), this.timeByteArray = new Uint8Array(this.fftSize), this.timeByteArrayL = new Uint8Array(this.fftSize), this.timeByteArrayR = new Uint8Array(this.fftSize), this.timeArray = new Int8Array(this.fftSize), this.timeByteArraySignedL = new Int8Array(this.fftSize), this.timeByteArraySignedR = new Int8Array(this.fftSize), this.tempTimeArrayL = new Int8Array(this.fftSize), this.tempTimeArrayR = new Int8Array(this.fftSize), this.timeArrayL = new Int8Array(this.numSamps), this.timeArrayR = new Int8Array(this.numSamps);
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "sampleAudio", value: function() {
              this.analyser.getByteTimeDomainData(this.timeByteArray), this.analyserL.getByteTimeDomainData(this.timeByteArrayL), this.analyserR.getByteTimeDomainData(this.timeByteArrayR), this.processAudio();
            } }, { key: "updateAudio", value: function(t3, e3, i3) {
              this.timeByteArray.set(t3), this.timeByteArrayL.set(e3), this.timeByteArrayR.set(i3), this.processAudio();
            } }, { key: "processAudio", value: function() {
              for (var t3 = 0, e3 = 0, i3 = 0; t3 < this.fftSize; t3++) this.timeArray[t3] = this.timeByteArray[t3] - 128, this.timeByteArraySignedL[t3] = this.timeByteArrayL[t3] - 128, this.timeByteArraySignedR[t3] = this.timeByteArrayR[t3] - 128, this.tempTimeArrayL[t3] = 0.5 * (this.timeByteArraySignedL[t3] + this.timeByteArraySignedL[i3]), this.tempTimeArrayR[t3] = 0.5 * (this.timeByteArraySignedR[t3] + this.timeByteArraySignedR[i3]), t3 % 2 == 0 && (this.timeArrayL[e3] = this.tempTimeArrayL[t3], this.timeArrayR[e3] = this.tempTimeArrayR[t3], e3 += 1), i3 = t3;
              this.freqArray = this.fft.timeToFrequencyDomain(this.timeArray), this.freqArrayL = this.fft.timeToFrequencyDomain(this.timeByteArraySignedL), this.freqArrayR = this.fft.timeToFrequencyDomain(this.timeByteArraySignedR);
            } }, { key: "connectAudio", value: function(t3) {
              t3.connect(this.audible);
            } }, { key: "disconnectAudio", value: function(t3) {
              t3.disconnect(this.audible);
            } }]) && a(e2.prototype, i2), s2 && a(e2, s2), t2;
          })();
          function o(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var n = (function() {
            function t2(e3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.audio = e3;
              var i3 = (this.audio.audioContext ? this.audio.audioContext.sampleRate : 44100) / this.audio.fftSize, s3 = Math.clamp(Math.round(20 / i3) - 1, 0, this.audio.numSamps - 1), r2 = Math.clamp(Math.round(320 / i3) - 1, 0, this.audio.numSamps - 1), a2 = Math.clamp(Math.round(2800 / i3) - 1, 0, this.audio.numSamps - 1), h2 = Math.clamp(Math.round(11025 / i3) - 1, 0, this.audio.numSamps - 1);
              this.starts = [s3, r2, a2], this.stops = [r2, a2, h2], this.val = new Float32Array(3), this.imm = new Float32Array(3), this.att = new Float32Array(3), this.avg = new Float32Array(3), this.longAvg = new Float32Array(3), this.att.fill(1), this.avg.fill(1), this.longAvg.fill(1);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "isFiniteNumber", value: function(t3) {
              return Number.isFinite(t3) && !Number.isNaN(t3);
            } }, { key: "adjustRateToFPS", value: function(t3, e3, i3) {
              return Math.pow(t3, e3 / i3);
            } }], (i2 = [{ key: "updateAudioLevels", value: function(e3, i3) {
              if (this.audio.freqArray.length > 0) {
                var s3 = e3;
                !t2.isFiniteNumber(s3) || s3 < 15 ? s3 = 15 : s3 > 144 && (s3 = 144), this.imm.fill(0);
                for (var r2 = 0; r2 < 3; r2++) for (var a2 = this.starts[r2]; a2 < this.stops[r2]; a2++) this.imm[r2] += this.audio.freqArray[a2];
                for (var h2 = 0; h2 < 3; h2++) {
                  var o2 = void 0;
                  o2 = this.imm[h2] > this.avg[h2] ? 0.2 : 0.5, o2 = t2.adjustRateToFPS(o2, 30, s3), this.avg[h2] = this.avg[h2] * o2 + this.imm[h2] * (1 - o2), o2 = i3 < 50 ? 0.9 : 0.992, o2 = t2.adjustRateToFPS(o2, 30, s3), this.longAvg[h2] = this.longAvg[h2] * o2 + this.imm[h2] * (1 - o2), this.longAvg[h2] < 1e-3 ? (this.val[h2] = 1, this.att[h2] = 1) : (this.val[h2] = this.imm[h2] / this.longAvg[h2], this.att[h2] = this.avg[h2] / this.longAvg[h2]);
                }
              }
            } }, { key: "bass", get: function() {
              return this.val[0];
            } }, { key: "bass_att", get: function() {
              return this.att[0];
            } }, { key: "mid", get: function() {
              return this.val[1];
            } }, { key: "mid_att", get: function() {
              return this.att[1];
            } }, { key: "treb", get: function() {
              return this.val[2];
            } }, { key: "treb_att", get: function() {
              return this.att[2];
            } }]) && o(e2.prototype, i2), s2 && o(e2, s2), t2;
          })(), l = i(0), m = i.n(l);
          function u(t2) {
            return (function(t3) {
              if (Array.isArray(t3)) {
                for (var e2 = 0, i2 = new Array(t3.length); e2 < t3.length; e2++) i2[e2] = t3[e2];
                return i2;
              }
            })(t2) || (function(t3) {
              if (Symbol.iterator in Object(t3) || "[object Arguments]" === Object.prototype.toString.call(t3)) return Array.from(t3);
            })(t2) || (function() {
              throw new TypeError("Invalid attempt to spread non-iterable instance");
            })();
          }
          function g(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var c = (function() {
            function t2() {
              !(function(t3, e3) {
                if (!(t3 instanceof e3)) throw new TypeError("Cannot call a class as a function");
              })(this, t2);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "atan2", value: function(t3, e3) {
              var i3 = Math.atan2(t3, e3);
              return i3 < 0 && (i3 += 2 * Math.PI), i3;
            } }, { key: "cloneVars", value: function(t3) {
              return Object.assign({}, t3);
            } }, { key: "range", value: function(t3, e3) {
              return void 0 === e3 ? u(Array(t3).keys()) : Array.from({ length: e3 - t3 }, function(e4, i3) {
                return i3 + t3;
              });
            } }, { key: "pick", value: function(t3, e3) {
              for (var i3 = {}, s3 = 0; s3 < e3.length; s3++) {
                var r2 = e3[s3];
                i3[r2] = t3[r2];
              }
              return i3;
            } }, { key: "omit", value: function(t3, e3) {
              for (var i3 = Object.assign({}, t3), s3 = 0; s3 < e3.length; s3++) {
                delete i3[e3[s3]];
              }
              return i3;
            } }], (i2 = null) && g(e2.prototype, i2), s2 && g(e2, s2), t2;
          })();
          function A(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var f = (function() {
            function t2(e3, i3, s3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.preset = e3, this.texsizeX = s3.texsizeX, this.texsizeY = s3.texsizeY, this.mesh_width = s3.mesh_width, this.mesh_height = s3.mesh_height, this.aspectx = s3.aspectx, this.aspecty = s3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.qs = c.range(1, 33).map(function(t3) {
                return "q".concat(t3);
              }), this.ts = c.range(1, 9).map(function(t3) {
                return "t".concat(t3);
              }), this.regs = c.range(100).map(function(t3) {
                return t3 < 10 ? "reg0".concat(t3) : "reg".concat(t3);
              }), this.initializeEquations(i3);
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "initializeEquations", value: function(t3) {
              this.runVertEQs = "" !== this.preset.pixel_eqs, this.mdVSQInit = null, this.mdVSRegs = null, this.mdVSFrame = null, this.mdVSUserKeys = null, this.mdVSFrameMap = null, this.mdVSShapes = null, this.mdVSUserKeysShapes = null, this.mdVSFrameMapShapes = null, this.mdVSWaves = null, this.mdVSUserKeysWaves = null, this.mdVSFrameMapWaves = null, this.mdVSQAfterFrame = null, this.gmegabuf = new Array(1048576).fill(0);
              var e3 = { frame: t3.frame, time: t3.time, fps: t3.fps, bass: t3.bass, bass_att: t3.bass_att, mid: t3.mid, mid_att: t3.mid_att, treb: t3.treb, treb_att: t3.treb_att, meshx: this.mesh_width, meshy: this.mesh_height, aspectx: this.invAspectx, aspecty: this.invAspecty, pixelsx: this.texsizeX, pixelsy: this.texsizeY, gmegabuf: this.gmegabuf };
              this.mdVS = Object.assign({}, this.preset.baseVals, e3), this.mdVS.megabuf = new Array(1048576).fill(0), this.mdVS.rand_start = new Float32Array([Math.random(), Math.random(), Math.random(), Math.random()]), this.mdVS.rand_preset = new Float32Array([Math.random(), Math.random(), Math.random(), Math.random()]);
              var i3 = this.qs.concat(this.regs, Object.keys(this.mdVS)), s3 = this.preset.init_eqs(c.cloneVars(this.mdVS));
              this.mdVSQInit = c.pick(s3, this.qs), this.mdVSRegs = c.pick(s3, this.regs);
              var r2 = c.pick(s3, Object.keys(c.omit(s3, i3)));
              if (r2.megabuf = s3.megabuf, r2.gmegabuf = s3.gmegabuf, this.mdVSFrame = this.preset.frame_eqs(Object.assign({}, this.mdVS, this.mdVSQInit, this.mdVSRegs, r2)), this.mdVSUserKeys = Object.keys(c.omit(this.mdVSFrame, i3)), this.mdVSFrameMap = c.pick(this.mdVSFrame, this.mdVSUserKeys), this.mdVSQAfterFrame = c.pick(this.mdVSFrame, this.qs), this.mdVSRegs = c.pick(this.mdVSFrame, this.regs), this.mdVSWaves = [], this.mdVSTWaveInits = [], this.mdVSUserKeysWaves = [], this.mdVSFrameMapWaves = [], this.preset.waves && this.preset.waves.length > 0) for (var a2 = 0; a2 < this.preset.waves.length; a2++) {
                var h2 = this.preset.waves[a2], o2 = h2.baseVals;
                if (0 !== o2.enabled) {
                  var n2 = Object.assign({}, o2, e3), l2 = this.qs.concat(this.ts, this.regs, Object.keys(n2));
                  Object.assign(n2, this.mdVSQAfterFrame, this.mdVSRegs), n2.megabuf = new Array(1048576).fill(0), h2.init_eqs && (n2 = h2.init_eqs(n2), this.mdVSRegs = c.pick(n2, this.regs), Object.assign(n2, o2)), this.mdVSWaves.push(n2), this.mdVSTWaveInits.push(c.pick(n2, this.ts)), this.mdVSUserKeysWaves.push(Object.keys(c.omit(n2, l2))), this.mdVSFrameMapWaves.push(c.pick(n2, this.mdVSUserKeysWaves[a2]));
                } else this.mdVSWaves.push({}), this.mdVSTWaveInits.push({}), this.mdVSUserKeysWaves.push([]), this.mdVSFrameMapWaves.push({});
              }
              if (this.mdVSShapes = [], this.mdVSTShapeInits = [], this.mdVSUserKeysShapes = [], this.mdVSFrameMapShapes = [], this.preset.shapes && this.preset.shapes.length > 0) for (var m2 = 0; m2 < this.preset.shapes.length; m2++) {
                var u2 = this.preset.shapes[m2], g2 = u2.baseVals;
                if (0 !== g2.enabled) {
                  var A2 = Object.assign({}, g2, e3), f2 = this.qs.concat(this.ts, this.regs, Object.keys(A2));
                  Object.assign(A2, this.mdVSQAfterFrame, this.mdVSRegs), A2.megabuf = new Array(1048576).fill(0), u2.init_eqs && (A2 = u2.init_eqs(A2), this.mdVSRegs = c.pick(A2, this.regs), Object.assign(A2, g2)), this.mdVSShapes.push(A2), this.mdVSTShapeInits.push(c.pick(A2, this.ts)), this.mdVSUserKeysShapes.push(Object.keys(c.omit(A2, f2))), this.mdVSFrameMapShapes.push(c.pick(A2, this.mdVSUserKeysShapes[m2]));
                } else this.mdVSShapes.push({}), this.mdVSTShapeInits.push({}), this.mdVSUserKeysShapes.push([]), this.mdVSFrameMapShapes.push({});
              }
            } }, { key: "updatePreset", value: function(t3, e3) {
              this.preset = t3, this.initializeEquations(e3);
            } }, { key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.mesh_width = t3.mesh_width, this.mesh_height = t3.mesh_height, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty;
            } }, { key: "runFrameEquations", value: function(t3) {
              this.mdVSFrame = Object.assign({}, this.mdVS, this.mdVSQInit, this.mdVSFrameMap, t3), this.mdVSFrame = this.preset.frame_eqs(this.mdVSFrame), this.mdVSFrameMap = c.pick(this.mdVSFrame, this.mdVSUserKeys), this.mdVSQAfterFrame = c.pick(this.mdVSFrame, this.qs);
            } }]) && A(e2.prototype, i2), s2 && A(e2, s2), t2;
          })();
          function d(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var v = /uniform sampler2D sampler_(?:.+?);/g, p = /uniform sampler2D sampler_(.+?);/, _ = (function() {
            function t2() {
              !(function(t3, e3) {
                if (!(t3 instanceof e3)) throw new TypeError("Cannot call a class as a function");
              })(this, t2);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "getShaderParts", value: function(t3) {
              var e3 = t3.indexOf("shader_body");
              if (t3 && e3 > -1) {
                var i3 = t3.substring(0, e3), s3 = t3.substring(e3), r2 = s3.indexOf("{"), a2 = s3.lastIndexOf("}");
                return [i3, s3.substring(r2 + 1, a2)];
              }
              return ["", t3];
            } }, { key: "getFragmentFloatPrecision", value: function(t3) {
              return t3.getShaderPrecisionFormat(t3.FRAGMENT_SHADER, t3.HIGH_FLOAT).precision > 0 ? "highp" : t3.getShaderPrecisionFormat(t3.FRAGMENT_SHADER, t3.MEDIUM_FLOAT).precision > 0 ? "mediump" : "lowp";
            } }, { key: "getUserSamplers", value: function(t3) {
              var e3 = [], i3 = t3.match(v);
              if (i3 && i3.length > 0) for (var s3 = 0; s3 < i3.length; s3++) {
                var r2 = i3[s3].match(p);
                if (r2 && r2.length > 0) {
                  var a2 = r2[1];
                  e3.push({ sampler: a2 });
                }
              }
              return e3;
            } }], (i2 = null) && d(e2.prototype, i2), s2 && d(e2, s2), t2;
          })();
          function x(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var b = (function() {
            function t2() {
              !(function(t3, e3) {
                if (!(t3 instanceof e3)) throw new TypeError("Cannot call a class as a function");
              })(this, t2);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "smoothWave", value: function(t3, e3, i3) {
              for (var s3, r2 = arguments.length > 3 && void 0 !== arguments[3] && arguments[3], a2 = 0, h2 = 0, o2 = 1, n2 = 0; n2 < i3 - 1; n2++) {
                s3 = o2, o2 = Math.min(i3 - 1, n2 + 2);
                for (var l2 = 0; l2 < 3; l2++) e3[3 * a2 + l2] = t3[3 * n2 + l2];
                if (r2) for (var m2 = 0; m2 < 3; m2++) e3[3 * (a2 + 1) + m2] = 0.5 * (-0.15 * t3[3 * h2 + m2] + 1.15 * t3[3 * n2 + m2] + 1.15 * t3[3 * s3 + m2] + -0.15 * t3[3 * o2 + m2]);
                else {
                  for (var u2 = 0; u2 < 2; u2++) e3[3 * (a2 + 1) + u2] = 0.5 * (-0.15 * t3[3 * h2 + u2] + 1.15 * t3[3 * n2 + u2] + 1.15 * t3[3 * s3 + u2] + -0.15 * t3[3 * o2 + u2]);
                  e3[3 * (a2 + 1) + 2] = 0;
                }
                h2 = n2, a2 += 2;
              }
              for (var g2 = 0; g2 < 3; g2++) e3[3 * a2 + g2] = t3[3 * (i3 - 1) + g2];
            } }, { key: "smoothWaveAndColor", value: function(t3, e3, i3, s3, r2) {
              for (var a2, h2 = arguments.length > 5 && void 0 !== arguments[5] && arguments[5], o2 = 0, n2 = 0, l2 = 1, m2 = 0; m2 < r2 - 1; m2++) {
                a2 = l2, l2 = Math.min(r2 - 1, m2 + 2);
                for (var u2 = 0; u2 < 3; u2++) i3[3 * o2 + u2] = t3[3 * m2 + u2];
                if (h2) for (var g2 = 0; g2 < 3; g2++) i3[3 * (o2 + 1) + g2] = 0.5 * (-0.15 * t3[3 * n2 + g2] + 1.15 * t3[3 * m2 + g2] + 1.15 * t3[3 * a2 + g2] + -0.15 * t3[3 * l2 + g2]);
                else {
                  for (var c2 = 0; c2 < 2; c2++) i3[3 * (o2 + 1) + c2] = 0.5 * (-0.15 * t3[3 * n2 + c2] + 1.15 * t3[3 * m2 + c2] + 1.15 * t3[3 * a2 + c2] + -0.15 * t3[3 * l2 + c2]);
                  i3[3 * (o2 + 1) + 2] = 0;
                }
                for (var A2 = 0; A2 < 4; A2++) s3[4 * o2 + A2] = e3[4 * m2 + A2], s3[4 * (o2 + 1) + A2] = e3[4 * m2 + A2];
                n2 = m2, o2 += 2;
              }
              for (var f2 = 0; f2 < 3; f2++) i3[3 * o2 + f2] = t3[3 * (r2 - 1) + f2];
              for (var d2 = 0; d2 < 4; d2++) s3[4 * o2 + d2] = e3[4 * (r2 - 1) + d2];
            } }], (i2 = null) && x(e2.prototype, i2), s2 && x(e2, s2), t2;
          })();
          function T(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var E = (function() {
            function t2(e3) {
              var i3 = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {};
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3;
              this.positions = new Float32Array(1536), this.positions2 = new Float32Array(1536), this.oldPositions = new Float32Array(1536), this.oldPositions2 = new Float32Array(1536), this.smoothedPositions = new Float32Array(3069), this.smoothedPositions2 = new Float32Array(3069), this.color = [0, 0, 0, 1], this.texsizeX = i3.texsizeX, this.texsizeY = i3.texsizeY, this.aspectx = i3.aspectx, this.aspecty = i3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader(), this.vertexBuf = this.gl.createBuffer();
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "processWaveform", value: function(t3, e3) {
              var i3 = [], s3 = e3.wave_scale / 128, r2 = e3.wave_smoothing, a2 = s3 * (1 - r2);
              i3.push(t3[0] * s3);
              for (var h2 = 1; h2 < t3.length; h2++) i3.push(t3[h2] * a2 + i3[h2 - 1] * r2);
              return i3;
            } }], (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty;
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      in vec3 aPos;\n                                      uniform vec2 thickOffset;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos + vec3(thickOffset, 0.0), 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      out vec4 fragColor;\n                                      uniform vec4 u_color;\n                                      void main(void) {\n                                        fragColor = u_color;\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.aPosLoc = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.colorLoc = this.gl.getUniformLocation(this.shaderProgram, "u_color"), this.thickOffsetLoc = this.gl.getUniformLocation(this.shaderProgram, "thickOffset");
            } }, { key: "generateWaveform", value: function(e3, i3, s3, r2, a2) {
              var h2 = a2.wave_a, o2 = (a2.bass + a2.mid + a2.treb) / 3;
              if (o2 > -0.01 && h2 > 1e-3 && s3.length > 0) {
                var n2 = t2.processWaveform(s3, a2), l2 = t2.processWaveform(r2, a2), m2 = Math.floor(a2.wave_mode) % 8, u2 = Math.floor(a2.old_wave_mode) % 8, g2 = 2 * a2.wave_x - 1, c2 = 2 * a2.wave_y - 1;
                this.numVert = 0, this.oldNumVert = 0;
                for (var A2 = e3 && m2 !== u2 ? 2 : 1, f2 = 0; f2 < A2; f2++) {
                  var d2 = 0 === f2 ? m2 : u2, v2 = a2.wave_mystery;
                  0 !== d2 && 1 !== d2 && 4 !== d2 || !(v2 < -1 || v2 > 1) || (v2 = 0.5 * v2 + 0.5, v2 -= Math.floor(v2), v2 = 2 * (v2 = Math.abs(v2)) - 1);
                  var p2 = void 0, _2 = void 0, x2 = void 0;
                  if (0 === f2 ? (_2 = this.positions, x2 = this.positions2) : (_2 = this.oldPositions, x2 = this.oldPositions2), h2 = a2.wave_a, 0 === d2) {
                    if (a2.modwavealphabyvolume > 0) {
                      var T2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / T2;
                    }
                    h2 = Math.clamp(h2, 0, 1);
                    for (var E2 = 1 / ((p2 = Math.floor(n2.length / 2) + 1) - 1), P2 = Math.floor((n2.length - p2) / 2), R2 = 0; R2 < p2 - 1; R2++) {
                      var L2 = 0.5 + 0.4 * l2[R2 + P2] + v2, S2 = R2 * E2 * 2 * Math.PI + 0.2 * a2.time;
                      if (R2 < p2 / 10) {
                        var y2 = R2 / (0.1 * p2);
                        L2 = (1 - (y2 = 0.5 - 0.5 * Math.cos(y2 * Math.PI))) * (0.5 + 0.4 * l2[R2 + p2 + P2] + v2) + L2 * y2;
                      }
                      _2[3 * R2 + 0] = L2 * Math.cos(S2) * this.aspecty + g2, _2[3 * R2 + 1] = L2 * Math.sin(S2) * this.aspectx + c2, _2[3 * R2 + 2] = 0;
                    }
                    _2[3 * (p2 - 1) + 0] = _2[0], _2[3 * (p2 - 1) + 1] = _2[1], _2[3 * (p2 - 1) + 2] = 0;
                  } else if (1 === d2) {
                    if (h2 *= 1.25, a2.modwavealphabyvolume > 0) {
                      var w2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / w2;
                    }
                    h2 = Math.clamp(h2, 0, 1), p2 = Math.floor(n2.length / 2);
                    for (var U2 = 0; U2 < p2; U2++) {
                      var M2 = 0.53 + 0.43 * l2[U2] + v2, F2 = 0.5 * n2[U2 + 32] * Math.PI + 2.3 * a2.time;
                      _2[3 * U2 + 0] = M2 * Math.cos(F2) * this.aspecty + g2, _2[3 * U2 + 1] = M2 * Math.sin(F2) * this.aspectx + c2, _2[3 * U2 + 2] = 0;
                    }
                  } else if (2 === d2) {
                    if (this.texsizeX < 1024 ? h2 *= 0.09 : this.texsizeX >= 1024 && this.texsizeX < 2048 ? h2 *= 0.11 : h2 *= 0.13, a2.modwavealphabyvolume > 0) {
                      var q2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / q2;
                    }
                    h2 = Math.clamp(h2, 0, 1), p2 = n2.length;
                    for (var z2 = 0; z2 < n2.length; z2++) _2[3 * z2 + 0] = l2[z2] * this.aspecty + g2, _2[3 * z2 + 1] = n2[(z2 + 32) % n2.length] * this.aspectx + c2, _2[3 * z2 + 2] = 0;
                  } else if (3 === d2) {
                    if (this.texsizeX < 1024 ? h2 *= 0.15 : this.texsizeX >= 1024 && this.texsizeX < 2048 ? h2 *= 0.22 : h2 *= 0.33, h2 *= 1.3, h2 *= a2.treb * a2.treb, a2.modwavealphabyvolume > 0) {
                      var B2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / B2;
                    }
                    h2 = Math.clamp(h2, 0, 1), p2 = n2.length;
                    for (var C2 = 0; C2 < n2.length; C2++) _2[3 * C2 + 0] = l2[C2] * this.aspecty + g2, _2[3 * C2 + 1] = n2[(C2 + 32) % n2.length] * this.aspectx + c2, _2[3 * C2 + 2] = 0;
                  } else if (4 === d2) {
                    if (a2.modwavealphabyvolume > 0) {
                      var D2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / D2;
                    }
                    h2 = Math.clamp(h2, 0, 1), (p2 = n2.length) > this.texsizeX / 3 && (p2 = Math.floor(this.texsizeX / 3));
                    for (var V2 = 1 / p2, I2 = Math.floor((n2.length - p2) / 2), X2 = 0.45 + 0.5 * (0.5 * v2 + 0.5), k2 = 1 - X2, N2 = 0; N2 < p2; N2++) {
                      var O2 = 2 * N2 * V2 + (g2 - 1) + 0.44 * l2[(N2 + 25 + I2) % n2.length], W2 = 0.47 * n2[N2 + I2] + c2;
                      N2 > 1 && (O2 = O2 * k2 + X2 * (2 * _2[3 * (N2 - 1) + 0] - _2[3 * (N2 - 2) + 0]), W2 = W2 * k2 + X2 * (2 * _2[3 * (N2 - 1) + 1] - _2[3 * (N2 - 2) + 1])), _2[3 * N2 + 0] = O2, _2[3 * N2 + 1] = W2, _2[3 * N2 + 2] = 0;
                    }
                  } else if (5 === d2) {
                    if (this.texsizeX < 1024 ? h2 *= 0.09 : this.texsizeX >= 1024 && this.texsizeX < 2048 ? h2 *= 0.11 : h2 *= 0.13, a2.modwavealphabyvolume > 0) {
                      var Q2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / Q2;
                    }
                    h2 = Math.clamp(h2, 0, 1);
                    var Y2 = Math.cos(0.3 * a2.time), G2 = Math.sin(0.3 * a2.time);
                    p2 = n2.length;
                    for (var H2 = 0; H2 < n2.length; H2++) {
                      var j2 = (H2 + 32) % n2.length, K2 = l2[H2] * n2[j2] + n2[H2] * l2[j2], J2 = l2[H2] * l2[H2] - n2[j2] * n2[j2];
                      _2[3 * H2 + 0] = (K2 * Y2 - J2 * G2) * (this.aspecty + g2), _2[3 * H2 + 1] = (K2 * G2 + J2 * Y2) * (this.aspectx + c2), _2[3 * H2 + 2] = 0;
                    }
                  } else if (6 === d2 || 7 === d2) {
                    if (a2.modwavealphabyvolume > 0) {
                      var Z2 = a2.modwavealphaend - a2.modwavealphastart;
                      h2 *= (o2 - a2.modwavealphastart) / Z2;
                    }
                    h2 = Math.clamp(h2, 0, 1), (p2 = Math.floor(n2.length / 2)) > this.texsizeX / 3 && (p2 = Math.floor(this.texsizeX / 3));
                    for (var $2 = Math.floor((n2.length - p2) / 2), tt2 = 0.5 * Math.PI * v2, et2 = Math.cos(tt2), it2 = Math.sin(tt2), st2 = [g2 * Math.cos(tt2 + 0.5 * Math.PI) - 3 * et2, g2 * Math.cos(tt2 + 0.5 * Math.PI) + 3 * et2], rt2 = [g2 * Math.sin(tt2 + 0.5 * Math.PI) - 3 * it2, g2 * Math.sin(tt2 + 0.5 * Math.PI) + 3 * it2], at2 = 0; at2 < 2; at2++) for (var ht2 = 0; ht2 < 4; ht2++) {
                      var ot2 = void 0, nt = false;
                      switch (ht2) {
                        case 0:
                          st2[at2] > 1.1 && (ot2 = (1.1 - st2[1 - at2]) / (st2[at2] - st2[1 - at2]), nt = true);
                          break;
                        case 1:
                          st2[at2] < -1.1 && (ot2 = (-1.1 - st2[1 - at2]) / (st2[at2] - st2[1 - at2]), nt = true);
                          break;
                        case 2:
                          rt2[at2] > 1.1 && (ot2 = (1.1 - rt2[1 - at2]) / (rt2[at2] - rt2[1 - at2]), nt = true);
                          break;
                        case 3:
                          rt2[at2] < -1.1 && (ot2 = (-1.1 - rt2[1 - at2]) / (rt2[at2] - rt2[1 - at2]), nt = true);
                      }
                      if (nt) {
                        var lt = st2[at2] - st2[1 - at2], mt = rt2[at2] - rt2[1 - at2];
                        st2[at2] = st2[1 - at2] + lt * ot2, rt2[at2] = rt2[1 - at2] + mt * ot2;
                      }
                    }
                    et2 = (st2[1] - st2[0]) / p2, it2 = (rt2[1] - rt2[0]) / p2;
                    var ut = Math.atan2(it2, et2), gt = Math.cos(ut + 0.5 * Math.PI), ct = Math.sin(ut + 0.5 * Math.PI);
                    if (6 === d2) for (var At = 0; At < p2; At++) {
                      var ft = n2[At + $2];
                      _2[3 * At + 0] = st2[0] + et2 * At + 0.25 * gt * ft, _2[3 * At + 1] = rt2[0] + it2 * At + 0.25 * ct * ft, _2[3 * At + 2] = 0;
                    }
                    else if (7 === d2) {
                      for (var dt = Math.pow(0.5 * c2 + 0.5, 2), vt = 0; vt < p2; vt++) {
                        var pt = n2[vt + $2];
                        _2[3 * vt + 0] = st2[0] + et2 * vt + gt * (0.25 * pt + dt), _2[3 * vt + 1] = rt2[0] + it2 * vt + ct * (0.25 * pt + dt), _2[3 * vt + 2] = 0;
                      }
                      for (var _t = 0; _t < p2; _t++) {
                        var xt = l2[_t + $2];
                        x2[3 * _t + 0] = st2[0] + et2 * _t + gt * (0.25 * xt - dt), x2[3 * _t + 1] = rt2[0] + it2 * _t + ct * (0.25 * xt - dt), x2[3 * _t + 2] = 0;
                      }
                    }
                  }
                  0 === f2 ? (this.positions = _2, this.positions2 = x2, this.numVert = p2, this.alpha = h2) : (this.oldPositions = _2, this.oldPositions2 = x2, this.oldNumVert = p2, this.oldAlpha = h2);
                }
                var bt = 0.5 - 0.5 * Math.cos(i3 * Math.PI), Tt = 1 - bt;
                this.oldNumVert > 0 && (h2 = bt * this.alpha + Tt * this.oldAlpha);
                var Et = Math.clamp(a2.wave_r, 0, 1), Pt = Math.clamp(a2.wave_g, 0, 1), Rt = Math.clamp(a2.wave_b, 0, 1);
                if (0 !== a2.wave_brighten) {
                  var Lt = Math.max(Et, Pt, Rt);
                  Lt > 0.01 && (Et /= Lt, Pt /= Lt, Rt /= Lt);
                }
                if (this.color = [Et, Pt, Rt, h2], this.oldNumVert > 0) if (7 === m2) {
                  for (var St = (this.oldNumVert - 1) / (2 * this.numVert), yt = 0; yt < this.numVert; yt++) {
                    var wt = yt * St, Ut = Math.floor(wt), Mt = wt - Ut, Ft = this.oldPositions[3 * Ut + 0] * (1 - Mt) + this.oldPositions[3 * (Ut + 1) + 0] * Mt, qt = this.oldPositions[3 * Ut + 1] * (1 - Mt) + this.oldPositions[3 * (Ut + 1) + 1] * Mt;
                    this.positions[3 * yt + 0] = this.positions[3 * yt + 0] * bt + Ft * Tt, this.positions[3 * yt + 1] = this.positions[3 * yt + 1] * bt + qt * Tt, this.positions[3 * yt + 2] = 0;
                  }
                  for (var zt = 0; zt < this.numVert; zt++) {
                    var Bt = (zt + this.numVert) * St, Ct = Math.floor(Bt), Dt = Bt - Ct, Vt = this.oldPositions[3 * Ct + 0] * (1 - Dt) + this.oldPositions[3 * (Ct + 1) + 0] * Dt, It = this.oldPositions[3 * Ct + 1] * (1 - Dt) + this.oldPositions[3 * (Ct + 1) + 1] * Dt;
                    this.positions2[3 * zt + 0] = this.positions2[3 * zt + 0] * bt + Vt * Tt, this.positions2[3 * zt + 1] = this.positions2[3 * zt + 1] * bt + It * Tt, this.positions2[3 * zt + 2] = 0;
                  }
                } else if (7 === u2) {
                  for (var Xt = this.numVert / 2, kt = (this.oldNumVert - 1) / Xt, Nt = 0; Nt < Xt; Nt++) {
                    var Ot = Nt * kt, Wt = Math.floor(Ot), Qt = Ot - Wt, Yt = this.oldPositions[3 * Wt + 0] * (1 - Qt) + this.oldPositions[3 * (Wt + 1) + 0] * Qt, Gt = this.oldPositions[3 * Wt + 1] * (1 - Qt) + this.oldPositions[3 * (Wt + 1) + 1] * Qt;
                    this.positions[3 * Nt + 0] = this.positions[3 * Nt + 0] * bt + Yt * Tt, this.positions[3 * Nt + 1] = this.positions[3 * Nt + 1] * bt + Gt * Tt, this.positions[3 * Nt + 2] = 0;
                  }
                  for (var Ht = 0; Ht < Xt; Ht++) {
                    var jt = Ht * kt, Kt = Math.floor(jt), Jt = jt - Kt, Zt = this.oldPositions2[3 * Kt + 0] * (1 - Jt) + this.oldPositions2[3 * (Kt + 1) + 0] * Jt, $t = this.oldPositions2[3 * Kt + 1] * (1 - Jt) + this.oldPositions2[3 * (Kt + 1) + 1] * Jt;
                    this.positions2[3 * Ht + 0] = this.positions[3 * (Ht + Xt) + 0] * bt + Zt * Tt, this.positions2[3 * Ht + 1] = this.positions[3 * (Ht + Xt) + 1] * bt + $t * Tt, this.positions2[3 * Ht + 2] = 0;
                  }
                } else for (var te = (this.oldNumVert - 1) / this.numVert, ee = 0; ee < this.numVert; ee++) {
                  var ie = ee * te, se = Math.floor(ie), re = ie - se, ae = this.oldPositions[3 * se + 0] * (1 - re) + this.oldPositions[3 * (se + 1) + 0] * re, he = this.oldPositions[3 * se + 1] * (1 - re) + this.oldPositions[3 * (se + 1) + 1] * re;
                  this.positions[3 * ee + 0] = this.positions[3 * ee + 0] * bt + ae * Tt, this.positions[3 * ee + 1] = this.positions[3 * ee + 1] * bt + he * Tt, this.positions[3 * ee + 2] = 0;
                }
                for (var oe = 0; oe < this.numVert; oe++) this.positions[3 * oe + 1] = -this.positions[3 * oe + 1];
                if (this.smoothedNumVert = 2 * this.numVert - 1, b.smoothWave(this.positions, this.smoothedPositions, this.numVert), 7 === m2 || 7 === u2) {
                  for (var ne = 0; ne < this.numVert; ne++) this.positions2[3 * ne + 1] = -this.positions2[3 * ne + 1];
                  b.smoothWave(this.positions2, this.smoothedPositions2, this.numVert);
                }
                return true;
              }
              return false;
            } }, { key: "drawBasicWaveform", value: function(t3, e3, i3, s3, r2) {
              if (this.generateWaveform(t3, e3, i3, s3, r2)) {
                this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.smoothedPositions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aPosLoc, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLoc), this.gl.uniform4fv(this.colorLoc, this.color);
                var a2 = 1;
                0 === r2.wave_thick && 0 === r2.wave_dots || (a2 = 4), 0 !== r2.additivewave ? this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE) : this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
                for (var h2 = 0 !== r2.wave_dots ? this.gl.POINTS : this.gl.LINE_STRIP, o2 = 0; o2 < a2; o2++) {
                  0 === o2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 0]) : 1 === o2 ? this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 0]) : 2 === o2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 2 / this.texsizeY]) : 3 === o2 && this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 2 / this.texsizeY]), this.gl.drawArrays(h2, 0, this.smoothedNumVert);
                }
                if (7 === Math.floor(r2.wave_mode) % 8) {
                  this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.smoothedPositions2, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aPosLoc, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLoc);
                  for (var n2 = 0; n2 < a2; n2++) {
                    0 === n2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 0]) : 1 === n2 ? this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 0]) : 2 === n2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 2 / this.texsizeY]) : 3 === n2 && this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 2 / this.texsizeY]), this.gl.drawArrays(h2, 0, this.smoothedNumVert);
                  }
                }
              }
            } }]) && T(e2.prototype, i2), s2 && T(e2, s2), t2;
          })();
          function P(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var R = (function() {
            function t2(e3, i3, s3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.index = e3, this.gl = i3;
              this.pointsData = [new Float32Array(512), new Float32Array(512)], this.positions = new Float32Array(1536), this.colors = new Float32Array(2048), this.smoothedPositions = new Float32Array(3069), this.smoothedColors = new Float32Array(4092), this.texsizeX = s3.texsizeX, this.texsizeY = s3.texsizeY, this.mesh_width = s3.mesh_width, this.mesh_height = s3.mesh_height, this.aspectx = s3.aspectx, this.aspecty = s3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.positionVertexBuf = this.gl.createBuffer(), this.colorVertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.mesh_width = t3.mesh_width, this.mesh_height = t3.mesh_height, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty;
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      uniform float uSize;\n                                      uniform vec2 thickOffset;\n                                      in vec3 aPos;\n                                      in vec4 aColor;\n                                      out vec4 vColor;\n                                      void main(void) {\n                                        vColor = aColor;\n                                        gl_PointSize = uSize;\n                                        gl_Position = vec4(aPos + vec3(thickOffset, 0.0), 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      in vec4 vColor;\n                                      out vec4 fragColor;\n                                      void main(void) {\n                                        fragColor = vColor;\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.aPosLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.aColorLocation = this.gl.getAttribLocation(this.shaderProgram, "aColor"), this.sizeLoc = this.gl.getUniformLocation(this.shaderProgram, "uSize"), this.thickOffsetLoc = this.gl.getUniformLocation(this.shaderProgram, "thickOffset");
            } }, { key: "generateWaveform", value: function(t3, e3, i3, s3, r2, a2, h2, o2) {
              if (0 !== h2.baseVals.enabled && t3.length > 0) {
                var n2 = Object.assign({}, a2.mdVSWaves[this.index], a2.mdVSFrameMapWaves[this.index], a2.mdVSQAfterFrame, a2.mdVSTWaveInits[this.index], r2), l2 = h2.frame_eqs(n2);
                Object.prototype.hasOwnProperty.call(l2, "samples") ? this.samples = l2.samples : this.samples = 512, this.samples > 512 && (this.samples = 512), this.samples = Math.floor(this.samples);
                var m2 = Math.floor(l2.sep), u2 = l2.scaling, g2 = l2.spectrum, A2 = l2.smoothing, f2 = l2.usedots, d2 = l2.r, v2 = l2.g, p2 = l2.b, _2 = l2.a, x2 = a2.mdVS.wave_scale;
                if (this.samples -= m2, this.samples >= 2 || 0 !== f2 && this.samples >= 1) {
                  var T2 = 0 !== g2, E2 = (T2 ? 0.15 : 4e-3) * u2 * x2, P2 = T2 ? i3 : t3, R2 = T2 ? s3 : e3, L2 = T2 ? 0 : Math.floor((512 - this.samples) / 2 - m2 / 2), S2 = T2 ? 0 : Math.floor((512 - this.samples) / 2 + m2 / 2), y2 = T2 ? (512 - m2) / this.samples : 1, w2 = Math.pow(0.98 * A2, 0.5), U2 = 1 - w2;
                  this.pointsData[0][0] = P2[L2], this.pointsData[1][0] = R2[S2];
                  for (var M2 = 1; M2 < this.samples; M2++) {
                    var F2 = P2[Math.floor(M2 * y2 + L2)], q2 = R2[Math.floor(M2 * y2 + S2)];
                    this.pointsData[0][M2] = F2 * U2 + this.pointsData[0][M2 - 1] * w2, this.pointsData[1][M2] = q2 * U2 + this.pointsData[1][M2 - 1] * w2;
                  }
                  for (var z2 = this.samples - 2; z2 >= 0; z2--) this.pointsData[0][z2] = this.pointsData[0][z2] * U2 + this.pointsData[0][z2 + 1] * w2, this.pointsData[1][z2] = this.pointsData[1][z2] * U2 + this.pointsData[1][z2 + 1] * w2;
                  for (var B2 = 0; B2 < this.samples; B2++) this.pointsData[0][B2] *= E2, this.pointsData[1][B2] *= E2;
                  for (var C2 = 0; C2 < this.samples; C2++) {
                    var D2 = this.pointsData[0][C2], V2 = this.pointsData[1][C2];
                    l2.sample = C2 / (this.samples - 1), l2.value1 = D2, l2.value2 = V2, l2.x = 0.5 + D2, l2.y = 0.5 + V2, l2.r = d2, l2.g = v2, l2.b = p2, l2.a = _2, "" !== h2.point_eqs && (l2 = h2.point_eqs(l2));
                    var I2 = (2 * l2.x - 1) * this.invAspectx, X2 = (-2 * l2.y + 1) * this.invAspecty, k2 = l2.r, N2 = l2.g, O2 = l2.b, W2 = l2.a;
                    this.positions[3 * C2 + 0] = I2, this.positions[3 * C2 + 1] = X2, this.positions[3 * C2 + 2] = 0, this.colors[4 * C2 + 0] = k2, this.colors[4 * C2 + 1] = N2, this.colors[4 * C2 + 2] = O2, this.colors[4 * C2 + 3] = W2 * o2;
                  }
                  var Q2 = a2.mdVSUserKeysWaves[this.index], Y2 = c.pick(l2, Q2);
                  return a2.mdVSFrameMapWaves[this.index] = Y2, this.mdVSWaveFrame = l2, 0 === f2 && b.smoothWaveAndColor(this.positions, this.colors, this.smoothedPositions, this.smoothedColors, this.samples), true;
                }
              }
              return false;
            } }, { key: "drawCustomWaveform", value: function(t3, e3, i3, s3, r2, a2, h2, o2) {
              if (o2 && this.generateWaveform(e3, i3, s3, r2, a2, h2, o2, t3)) {
                this.gl.useProgram(this.shaderProgram);
                var n2, l2, m2, u2 = 0 !== this.mdVSWaveFrame.usedots, g2 = 0 !== this.mdVSWaveFrame.thick, c2 = 0 !== this.mdVSWaveFrame.additive;
                u2 ? (n2 = this.positions, l2 = this.colors, m2 = this.samples) : (n2 = this.smoothedPositions, l2 = this.smoothedColors, m2 = 2 * this.samples - 1), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, n2, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aPosLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.colorVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, l2, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aColorLocation, 4, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aColorLocation);
                var A2 = 1;
                u2 ? g2 ? this.gl.uniform1f(this.sizeLoc, 2 + (this.texsizeX >= 1024 ? 1 : 0)) : this.gl.uniform1f(this.sizeLoc, 1 + (this.texsizeX >= 1024 ? 1 : 0)) : (this.gl.uniform1f(this.sizeLoc, 1), g2 && (A2 = 4)), c2 ? this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE) : this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
                for (var f2 = u2 ? this.gl.POINTS : this.gl.LINE_STRIP, d2 = 0; d2 < A2; d2++) {
                  0 === d2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 0]) : 1 === d2 ? this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 0]) : 2 === d2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 2 / this.texsizeY]) : 3 === d2 && this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 2 / this.texsizeY]), this.gl.drawArrays(f2, 0, m2);
                }
              }
            } }]) && P(e2.prototype, i2), s2 && P(e2, s2), t2;
          })();
          function L(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var S = (function() {
            function t2(e3, i3, s3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.index = e3, this.gl = i3;
              this.positions = new Float32Array(309), this.colors = new Float32Array(412), this.uvs = new Float32Array(206), this.borderPositions = new Float32Array(306), this.texsizeX = s3.texsizeX, this.texsizeY = s3.texsizeY, this.mesh_width = s3.mesh_width, this.mesh_height = s3.mesh_height, this.aspectx = s3.aspectx, this.aspecty = s3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.positionVertexBuf = this.gl.createBuffer(), this.colorVertexBuf = this.gl.createBuffer(), this.uvVertexBuf = this.gl.createBuffer(), this.borderPositionVertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader(), this.createBorderShader(), this.mainSampler = this.gl.createSampler(), i3.samplerParameteri(this.mainSampler, i3.TEXTURE_MIN_FILTER, i3.LINEAR_MIPMAP_LINEAR), i3.samplerParameteri(this.mainSampler, i3.TEXTURE_MAG_FILTER, i3.LINEAR), i3.samplerParameteri(this.mainSampler, i3.TEXTURE_WRAP_S, i3.REPEAT), i3.samplerParameteri(this.mainSampler, i3.TEXTURE_WRAP_T, i3.REPEAT);
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.mesh_width = t3.mesh_width, this.mesh_height = t3.mesh_height, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty;
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      in vec3 aPos;\n                                      in vec4 aColor;\n                                      in vec2 aUv;\n                                      out vec4 vColor;\n                                      out vec2 vUv;\n                                      void main(void) {\n                                        vColor = aColor;\n                                        vUv = aUv;\n                                        gl_Position = vec4(aPos, 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      uniform sampler2D uTexture;\n                                      uniform float uTextured;\n                                      in vec4 vColor;\n                                      in vec2 vUv;\n                                      out vec4 fragColor;\n                                      void main(void) {\n                                        if (uTextured != 0.0) {\n                                          fragColor = texture(uTexture, vUv) * vColor;\n                                        } else {\n                                          fragColor = vColor;\n                                        }\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.aPosLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.aColorLocation = this.gl.getAttribLocation(this.shaderProgram, "aColor"), this.aUvLocation = this.gl.getAttribLocation(this.shaderProgram, "aUv"), this.texturedLoc = this.gl.getUniformLocation(this.shaderProgram, "uTextured"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture");
            } }, { key: "createBorderShader", value: function() {
              this.borderShaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      in vec3 aBorderPos;\n                                      uniform vec2 thickOffset;\n                                      void main(void) {\n                                        gl_Position = vec4(aBorderPos +\n                                                           vec3(thickOffset, 0.0), 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      out vec4 fragColor;\n                                      uniform vec4 uBorderColor;\n                                      void main(void) {\n                                        fragColor = uBorderColor;\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.borderShaderProgram, t3), this.gl.attachShader(this.borderShaderProgram, e3), this.gl.linkProgram(this.borderShaderProgram), this.aBorderPosLoc = this.gl.getAttribLocation(this.borderShaderProgram, "aBorderPos"), this.uBorderColorLoc = this.gl.getUniformLocation(this.borderShaderProgram, "uBorderColor"), this.thickOffsetLoc = this.gl.getUniformLocation(this.shaderProgram, "thickOffset");
            } }, { key: "drawCustomShape", value: function(t3, e3, i3, s3, r2) {
              if (0 !== s3.baseVals.enabled) {
                this.setupShapeBuffers(i3.mdVSFrame);
                for (var a2 = Object.assign({}, i3.mdVSShapes[this.index], i3.mdVSFrameMapShapes[this.index], i3.mdVSQAfterFrame, i3.mdVSTShapeInits[this.index], e3), h2 = c.cloneVars(a2), o2 = Math.clamp(a2.num_inst, 1, 1024), n2 = 0; n2 < o2; n2++) {
                  a2.instance = n2, a2.x = h2.x, a2.y = h2.y, a2.rad = h2.rad, a2.ang = h2.ang, a2.r = h2.r, a2.g = h2.g, a2.b = h2.b, a2.a = h2.a, a2.r2 = h2.r2, a2.g2 = h2.g2, a2.b2 = h2.b2, a2.a2 = h2.a2, a2.border_r = h2.border_r, a2.border_g = h2.border_g, a2.border_b = h2.border_b, a2.border_a = h2.border_a, a2.thickoutline = h2.thickoutline, a2.textured = h2.textured, a2.tex_zoom = h2.tex_zoom, a2.tex_ang = h2.tex_ang, a2.additive = h2.additive;
                  var l2 = s3.frame_eqs(a2), m2 = l2.sides;
                  m2 = Math.clamp(m2, 3, 100), m2 = Math.floor(m2);
                  var u2 = l2.rad, g2 = l2.ang, A2 = 2 * l2.x - 1, f2 = -2 * l2.y + 1, d2 = l2.r, v2 = l2.g, p2 = l2.b, _2 = l2.a, x2 = l2.r2, b2 = l2.g2, T2 = l2.b2, E2 = l2.a2, P2 = l2.border_r, R2 = l2.border_g, L2 = l2.border_b, S2 = l2.border_a;
                  this.borderColor = [P2, R2, L2, S2 * t3];
                  var y2 = l2.thickoutline, w2 = l2.textured, U2 = l2.tex_zoom, M2 = l2.tex_ang, F2 = l2.additive, q2 = this.borderColor[3] > 0, z2 = Math.abs(w2) >= 1, B2 = Math.abs(y2) >= 1, C2 = Math.abs(F2) >= 1;
                  this.positions[0] = A2, this.positions[1] = f2, this.positions[2] = 0, this.colors[0] = d2, this.colors[1] = v2, this.colors[2] = p2, this.colors[3] = _2 * t3, z2 && (this.uvs[0] = 0.5, this.uvs[1] = 0.5);
                  for (var D2 = 0.25 * Math.PI, V2 = 1; V2 <= m2 + 1; V2++) {
                    var I2 = 2 * ((V2 - 1) / m2) * Math.PI, X2 = I2 + g2 + D2;
                    if (this.positions[3 * V2 + 0] = A2 + u2 * Math.cos(X2) * this.aspecty, this.positions[3 * V2 + 1] = f2 + u2 * Math.sin(X2), this.positions[3 * V2 + 2] = 0, this.colors[4 * V2 + 0] = x2, this.colors[4 * V2 + 1] = b2, this.colors[4 * V2 + 2] = T2, this.colors[4 * V2 + 3] = E2 * t3, z2) {
                      var k2 = I2 + M2 + D2;
                      this.uvs[2 * V2 + 0] = 0.5 + 0.5 * Math.cos(k2) / U2 * this.aspecty, this.uvs[2 * V2 + 1] = 0.5 + 0.5 * Math.sin(k2) / U2;
                    }
                    q2 && (this.borderPositions[3 * (V2 - 1) + 0] = this.positions[3 * V2 + 0], this.borderPositions[3 * (V2 - 1) + 1] = this.positions[3 * V2 + 1], this.borderPositions[3 * (V2 - 1) + 2] = this.positions[3 * V2 + 2]);
                  }
                  this.mdVSShapeFrame = l2, this.drawCustomShapeInstance(r2, m2, z2, q2, B2, C2);
                }
                var N2 = i3.mdVSUserKeysShapes[this.index], O2 = c.pick(this.mdVSShapeFrame, N2);
                i3.mdVSFrameMapShapes[this.index] = O2;
              }
            } }, { key: "setupShapeBuffers", value: function(t3) {
              this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.DYNAMIC_DRAW), this.gl.vertexAttribPointer(this.aPosLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.colorVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.colors, this.gl.DYNAMIC_DRAW), this.gl.vertexAttribPointer(this.aColorLocation, 4, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aColorLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.uvVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.uvs, this.gl.DYNAMIC_DRAW), this.gl.vertexAttribPointer(this.aUvLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aUvLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.borderPositionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.borderPositions, this.gl.DYNAMIC_DRAW), this.gl.vertexAttribPointer(this.aBorderPosLoc, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aBorderPosLoc);
              var e3 = 0 !== t3.wrap ? this.gl.REPEAT : this.gl.CLAMP_TO_EDGE;
              this.gl.samplerParameteri(this.mainSampler, this.gl.TEXTURE_WRAP_S, e3), this.gl.samplerParameteri(this.mainSampler, this.gl.TEXTURE_WRAP_T, e3);
            } }, { key: "drawCustomShapeInstance", value: function(t3, e3, i3, s3, r2, a2) {
              this.gl.useProgram(this.shaderProgram);
              var h2 = new Float32Array(this.positions.buffer, 0, 3 * (e3 + 2));
              this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, h2), this.gl.vertexAttribPointer(this.aPosLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLocation);
              var o2 = new Float32Array(this.colors.buffer, 0, 4 * (e3 + 2));
              if (this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.colorVertexBuf), this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, o2), this.gl.vertexAttribPointer(this.aColorLocation, 4, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aColorLocation), i3) {
                var n2 = new Float32Array(this.uvs.buffer, 0, 2 * (e3 + 2));
                this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.uvVertexBuf), this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, n2), this.gl.vertexAttribPointer(this.aUvLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aUvLocation);
              }
              if (this.gl.uniform1f(this.texturedLoc, i3 ? 1 : 0), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.bindSampler(0, this.mainSampler), this.gl.uniform1i(this.textureLoc, 0), a2 ? this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE) : this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLE_FAN, 0, e3 + 2), s3) {
                this.gl.useProgram(this.borderShaderProgram);
                var l2 = new Float32Array(this.borderPositions.buffer, 0, 3 * (e3 + 1));
                this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.borderPositionVertexBuf), this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, l2), this.gl.vertexAttribPointer(this.aBorderPosLoc, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aBorderPosLoc), this.gl.uniform4fv(this.uBorderColorLoc, this.borderColor);
                for (var m2 = r2 ? 4 : 1, u2 = 0; u2 < m2; u2++) {
                  0 === u2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 0]) : 1 === u2 ? this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 0]) : 2 === u2 ? this.gl.uniform2fv(this.thickOffsetLoc, [0, 2 / this.texsizeY]) : 3 === u2 && this.gl.uniform2fv(this.thickOffsetLoc, [2 / this.texsizeX, 2 / this.texsizeY]), this.gl.drawArrays(this.gl.LINE_STRIP, 0, e3 + 1);
                }
              }
            } }]) && L(e2.prototype, i2), s2 && L(e2, s2), t2;
          })();
          function y(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var w = (function() {
            function t2(e3) {
              var i3 = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {};
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.positions = new Float32Array(72), this.aspectx = i3.aspectx, this.aspecty = i3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader(), this.vertexBuf = this.gl.createBuffer();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty;
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      in vec3 aPos;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos, 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      out vec4 fragColor;\n                                      uniform vec4 u_color;\n                                      void main(void) {\n                                        fragColor = u_color;\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.aPosLoc = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.colorLoc = this.gl.getUniformLocation(this.shaderProgram, "u_color");
            } }, { key: "addTriangle", value: function(t3, e3, i3, s3) {
              this.positions[t3 + 0] = e3[0], this.positions[t3 + 1] = e3[1], this.positions[t3 + 2] = e3[2], this.positions[t3 + 3] = i3[0], this.positions[t3 + 4] = i3[1], this.positions[t3 + 5] = i3[2], this.positions[t3 + 6] = s3[0], this.positions[t3 + 7] = s3[1], this.positions[t3 + 8] = s3[2];
            } }, { key: "generateBorder", value: function(t3, e3, i3) {
              if (e3 > 0 && t3[3] > 0) {
                var s3 = i3 / 2, r2 = e3 / 2 + s3, a2 = 2 * s3, h2 = 2 * s3, o2 = 2 * r2, n2 = 2 * r2, l2 = [-1 + a2, -1 + n2, 0], m2 = [-1 + a2, 1 - n2, 0], u2 = [-1 + o2, 1 - n2, 0], g2 = [-1 + o2, -1 + n2, 0];
                return this.addTriangle(0, g2, m2, l2), this.addTriangle(9, g2, u2, m2), l2 = [1 - a2, -1 + n2, 0], m2 = [1 - a2, 1 - n2, 0], u2 = [1 - o2, 1 - n2, 0], g2 = [1 - o2, -1 + n2, 0], this.addTriangle(18, l2, m2, g2), this.addTriangle(27, m2, u2, g2), l2 = [-1 + a2, -1 + h2, 0], m2 = [-1 + a2, n2 - 1, 0], u2 = [1 - a2, n2 - 1, 0], g2 = [1 - a2, -1 + h2, 0], this.addTriangle(36, g2, m2, l2), this.addTriangle(45, g2, u2, m2), l2 = [-1 + a2, 1 - h2, 0], m2 = [-1 + a2, 1 - n2, 0], u2 = [1 - a2, 1 - n2, 0], g2 = [1 - a2, 1 - h2, 0], this.addTriangle(54, l2, m2, g2), this.addTriangle(63, m2, u2, g2), true;
              }
              return false;
            } }, { key: "drawBorder", value: function(t3, e3, i3) {
              this.generateBorder(t3, e3, i3) && (this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aPosLoc, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLoc), this.gl.uniform4fv(this.colorLoc, t3), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLES, 0, this.positions.length / 3));
            } }]) && y(e2.prototype, i2), s2 && y(e2, s2), t2;
          })();
          function U(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var M = (function() {
            function t2(e3, i3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.aspectx = i3.aspectx, this.aspecty = i3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.generatePositions(), this.colors = new Float32Array([0, 0, 0, 3 / 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), this.positionVertexBuf = this.gl.createBuffer(), this.colorVertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.generatePositions();
            } }, { key: "generatePositions", value: function() {
              this.positions = new Float32Array([0, 0, 0, -0.05 * this.aspecty, 0, 0, 0, -0.05, 0, 0.05 * this.aspecty, 0, 0, 0, 0.05, 0, -0.05 * this.aspecty, 0, 0]);
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      in vec3 aPos;\n                                      in vec4 aColor;\n                                      out vec4 vColor;\n                                      void main(void) {\n                                        vColor = aColor;\n                                        gl_Position = vec4(aPos, 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      in vec4 vColor;\n                                      out vec4 fragColor;\n                                      void main(void) {\n                                        fragColor = vColor;\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.aPosLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.aColorLocation = this.gl.getAttribLocation(this.shaderProgram, "aColor");
            } }, { key: "drawDarkenCenter", value: function(t3) {
              0 !== t3.darken_center && (this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aPosLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.colorVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.colors, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aColorLocation, 4, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aColorLocation), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLE_FAN, 0, this.positions.length / 3));
            } }]) && U(e2.prototype, i2), s2 && U(e2, s2), t2;
          })();
          function F(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var q = (function() {
            function t2(e3, i3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.maxX = 64, this.maxY = 48, this.positions = new Float32Array(this.maxX * this.maxY * 2 * 3), this.texsizeX = i3.texsizeX, this.texsizeY = i3.texsizeY, this.mesh_width = i3.mesh_width, this.mesh_height = i3.mesh_height, this.positionVertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.mesh_width = t3.mesh_width, this.mesh_height = t3.mesh_height;
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      in vec3 aPos;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos, 1.0);\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      out vec4 fragColor;\n                                      uniform vec4 u_color;\n                                      void main(void) {\n                                        fragColor = u_color;\n                                      }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.aPosLoc = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.colorLoc = this.gl.getUniformLocation(this.shaderProgram, "u_color");
            } }, { key: "getMotionDir", value: function(t3, e3, i3) {
              var s3, r2, a2 = Math.floor(i3 * this.mesh_height), h2 = i3 * this.mesh_height - a2, o2 = Math.floor(e3 * this.mesh_width), n2 = e3 * this.mesh_width - o2, l2 = o2 + 1, m2 = a2 + 1, u2 = this.mesh_width + 1;
              return s3 = t3[2 * (a2 * u2 + o2) + 0] * (1 - n2) * (1 - h2), r2 = t3[2 * (a2 * u2 + o2) + 1] * (1 - n2) * (1 - h2), s3 += t3[2 * (a2 * u2 + l2) + 0] * n2 * (1 - h2), r2 += t3[2 * (a2 * u2 + l2) + 1] * n2 * (1 - h2), s3 += t3[2 * (m2 * u2 + o2) + 0] * (1 - n2) * h2, r2 += t3[2 * (m2 * u2 + o2) + 1] * (1 - n2) * h2, [s3 += t3[2 * (m2 * u2 + l2) + 0] * n2 * h2, 1 - (r2 += t3[2 * (m2 * u2 + l2) + 1] * n2 * h2)];
            } }, { key: "generateMotionVectors", value: function(t3, e3) {
              var i3 = t3.mv_a, s3 = Math.floor(t3.mv_x), r2 = Math.floor(t3.mv_y);
              if (i3 > 1e-3 && s3 > 0 && r2 > 0) {
                var a2 = t3.mv_x - s3, h2 = t3.mv_y - r2;
                s3 > this.maxX && (s3 = this.maxX, a2 = 0), r2 > this.maxY && (r2 = this.maxY, h2 = 0);
                var o2 = t3.mv_dx, n2 = t3.mv_dy, l2 = t3.mv_l, m2 = 1 / this.texsizeX;
                this.numVecVerts = 0;
                for (var u2 = 0; u2 < r2; u2++) {
                  var g2 = (u2 + 0.25) / (r2 + h2 + 0.25 - 1);
                  if ((g2 -= n2) > 1e-4 && g2 < 0.9999) for (var c2 = 0; c2 < s3; c2++) {
                    var A2 = (c2 + 0.25) / (s3 + a2 + 0.25 - 1);
                    if ((A2 += o2) > 1e-4 && A2 < 0.9999) {
                      var f2 = this.getMotionDir(e3, A2, g2), d2 = f2[0], v2 = f2[1], p2 = d2 - A2, _2 = v2 - g2;
                      p2 *= l2, _2 *= l2;
                      var x2 = Math.sqrt(p2 * p2 + _2 * _2);
                      x2 < m2 && x2 > 1e-8 ? (p2 *= x2 = m2 / x2, _2 *= x2) : (p2 = m2, p2 = m2);
                      var b2 = 2 * A2 - 1, T2 = 2 * g2 - 1, E2 = 2 * (d2 = A2 + p2) - 1, P2 = 2 * (v2 = g2 + _2) - 1;
                      this.positions[3 * this.numVecVerts + 0] = b2, this.positions[3 * this.numVecVerts + 1] = T2, this.positions[3 * this.numVecVerts + 2] = 0, this.positions[3 * (this.numVecVerts + 1) + 0] = E2, this.positions[3 * (this.numVecVerts + 1) + 1] = P2, this.positions[3 * (this.numVecVerts + 1) + 2] = 0, this.numVecVerts += 2;
                    }
                  }
                }
                if (this.numVecVerts > 0) return this.color = [t3.mv_r, t3.mv_g, t3.mv_b, i3], true;
              }
              return false;
            } }, { key: "drawMotionVectors", value: function(t3, e3) {
              this.generateMotionVectors(t3, e3) && (this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.aPosLoc, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.aPosLoc), this.gl.uniform4fv(this.colorLoc, this.color), this.gl.lineWidth(1), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.LINES, 0, this.numVecVerts));
            } }]) && F(e2.prototype, i2), s2 && F(e2, s2), t2;
          })();
          function z(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var B = (function() {
            function t2(e3, i3, s3) {
              var r2 = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {};
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.noise = i3, this.image = s3, this.texsizeX = r2.texsizeX, this.texsizeY = r2.texsizeY, this.mesh_width = r2.mesh_width, this.mesh_height = r2.mesh_height, this.aspectx = r2.aspectx, this.aspecty = r2.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.buildPositions(), this.indexBuf = e3.createBuffer(), this.positionVertexBuf = this.gl.createBuffer(), this.warpUvVertexBuf = this.gl.createBuffer(), this.warpColorVertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader(), this.mainSampler = this.gl.createSampler(), this.mainSamplerFW = this.gl.createSampler(), this.mainSamplerFC = this.gl.createSampler(), this.mainSamplerPW = this.gl.createSampler(), this.mainSamplerPC = this.gl.createSampler(), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_MIN_FILTER, e3.LINEAR_MIPMAP_LINEAR), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_MAG_FILTER, e3.LINEAR), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_WRAP_T, e3.REPEAT), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_MIN_FILTER, e3.LINEAR_MIPMAP_LINEAR), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_MAG_FILTER, e3.LINEAR), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_WRAP_T, e3.REPEAT), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_MIN_FILTER, e3.LINEAR_MIPMAP_LINEAR), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_MAG_FILTER, e3.LINEAR), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_WRAP_S, e3.CLAMP_TO_EDGE), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_WRAP_T, e3.CLAMP_TO_EDGE), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_MIN_FILTER, e3.NEAREST_MIPMAP_NEAREST), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_MAG_FILTER, e3.NEAREST), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_WRAP_T, e3.REPEAT), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_MIN_FILTER, e3.NEAREST_MIPMAP_NEAREST), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_MAG_FILTER, e3.NEAREST), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_WRAP_S, e3.CLAMP_TO_EDGE), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_WRAP_T, e3.CLAMP_TO_EDGE);
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "buildPositions", value: function() {
              for (var t3 = this.mesh_width, e3 = this.mesh_height, i3 = t3 + 1, s3 = e3 + 1, r2 = 2 / t3, a2 = 2 / e3, h2 = [], o2 = 0; o2 < s3; o2++) for (var n2 = o2 * a2 - 1, l2 = 0; l2 < i3; l2++) {
                var m2 = l2 * r2 - 1;
                h2.push(m2, -n2, 0);
              }
              for (var u2 = [], g2 = 0; g2 < e3; g2++) for (var c2 = 0; c2 < t3; c2++) {
                var A2 = c2 + i3 * g2, f2 = c2 + i3 * (g2 + 1), d2 = c2 + 1 + i3 * (g2 + 1), v2 = c2 + 1 + i3 * g2;
                u2.push(A2, f2, v2), u2.push(f2, d2, v2);
              }
              this.vertices = new Float32Array(h2), this.indices = new Uint16Array(u2);
            } }, { key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.mesh_width = t3.mesh_width, this.mesh_height = t3.mesh_height, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.buildPositions();
            } }, { key: "createShader", value: function() {
              var t3, e3, i3 = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : "";
              if (0 === i3.length) t3 = "ret = texture(sampler_main, uv).rgb * decay;", e3 = "";
              else {
                var s3 = _.getShaderParts(i3);
                e3 = s3[0], t3 = s3[1];
              }
              t3 = (t3 = t3.replace(/texture2D/g, "texture")).replace(/texture3D/g, "texture"), this.userTextures = _.getUserSamplers(e3), this.shaderProgram = this.gl.createProgram();
              var r2 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(r2, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      const vec2 halfmad = vec2(0.5);\n                                      in vec2 aPos;\n                                      in vec2 aWarpUv;\n                                      in vec4 aWarpColor;\n                                      out vec2 uv;\n                                      out vec2 uv_orig;\n                                      out vec4 vColor;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos, 0.0, 1.0);\n                                        uv_orig = aPos * halfmad + halfmad;\n                                        uv = aWarpUv;\n                                        vColor = aWarpColor;\n                                      }")), this.gl.compileShader(r2);
              var a2 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(a2, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      precision mediump sampler3D;\n\n                                      in vec2 uv;\n                                      in vec2 uv_orig;\n                                      in vec4 vColor;\n                                      out vec4 fragColor;\n                                      uniform sampler2D sampler_main;\n                                      uniform sampler2D sampler_fw_main;\n                                      uniform sampler2D sampler_fc_main;\n                                      uniform sampler2D sampler_pw_main;\n                                      uniform sampler2D sampler_pc_main;\n                                      uniform sampler2D sampler_blur1;\n                                      uniform sampler2D sampler_blur2;\n                                      uniform sampler2D sampler_blur3;\n                                      uniform sampler2D sampler_noise_lq;\n                                      uniform sampler2D sampler_noise_lq_lite;\n                                      uniform sampler2D sampler_noise_mq;\n                                      uniform sampler2D sampler_noise_hq;\n                                      uniform sampler2D sampler_pw_noise_lq;\n                                      uniform sampler3D sampler_noisevol_lq;\n                                      uniform sampler3D sampler_noisevol_hq;\n                                      uniform float time;\n                                      uniform float decay;\n                                      uniform vec2 resolution;\n                                      uniform vec4 aspect;\n                                      uniform vec4 texsize;\n                                      uniform vec4 texsize_noise_lq;\n                                      uniform vec4 texsize_noise_mq;\n                                      uniform vec4 texsize_noise_hq;\n                                      uniform vec4 texsize_noise_lq_lite;\n                                      uniform vec4 texsize_noisevol_lq;\n                                      uniform vec4 texsize_noisevol_hq;\n\n                                      uniform float bass;\n                                      uniform float mid;\n                                      uniform float treb;\n                                      uniform float vol;\n                                      uniform float bass_att;\n                                      uniform float mid_att;\n                                      uniform float treb_att;\n                                      uniform float vol_att;\n\n                                      uniform float frame;\n                                      uniform float fps;\n\n                                      uniform vec4 _qa;\n                                      uniform vec4 _qb;\n                                      uniform vec4 _qc;\n                                      uniform vec4 _qd;\n                                      uniform vec4 _qe;\n                                      uniform vec4 _qf;\n                                      uniform vec4 _qg;\n                                      uniform vec4 _qh;\n\n                                      #define q1 _qa.x\n                                      #define q2 _qa.y\n                                      #define q3 _qa.z\n                                      #define q4 _qa.w\n                                      #define q5 _qb.x\n                                      #define q6 _qb.y\n                                      #define q7 _qb.z\n                                      #define q8 _qb.w\n                                      #define q9 _qc.x\n                                      #define q10 _qc.y\n                                      #define q11 _qc.z\n                                      #define q12 _qc.w\n                                      #define q13 _qd.x\n                                      #define q14 _qd.y\n                                      #define q15 _qd.z\n                                      #define q16 _qd.w\n                                      #define q17 _qe.x\n                                      #define q18 _qe.y\n                                      #define q19 _qe.z\n                                      #define q20 _qe.w\n                                      #define q21 _qf.x\n                                      #define q22 _qf.y\n                                      #define q23 _qf.z\n                                      #define q24 _qf.w\n                                      #define q25 _qg.x\n                                      #define q26 _qg.y\n                                      #define q27 _qg.z\n                                      #define q28 _qg.w\n                                      #define q29 _qh.x\n                                      #define q30 _qh.y\n                                      #define q31 _qh.z\n                                      #define q32 _qh.w\n\n                                      uniform vec4 slow_roam_cos;\n                                      uniform vec4 roam_cos;\n                                      uniform vec4 slow_roam_sin;\n                                      uniform vec4 roam_sin;\n\n                                      uniform float blur1_min;\n                                      uniform float blur1_max;\n                                      uniform float blur2_min;\n                                      uniform float blur2_max;\n                                      uniform float blur3_min;\n                                      uniform float blur3_max;\n\n                                      uniform float scale1;\n                                      uniform float scale2;\n                                      uniform float scale3;\n                                      uniform float bias1;\n                                      uniform float bias2;\n                                      uniform float bias3;\n\n                                      uniform vec4 rand_frame;\n                                      uniform vec4 rand_preset;\n\n                                      float PI = ").concat(Math.PI, ";\n\n                                      ").concat(e3, "\n\n                                      void main(void) {\n                                        vec3 ret;\n                                        float rad = length(uv_orig - 0.5);\n                                        float ang = atan(uv_orig.x - 0.5, uv_orig.y - 0.5);\n\n                                        ").concat(t3, "\n\n                                        fragColor = vec4(ret, 1.0) * vColor;\n                                      }")), this.gl.compileShader(a2), this.gl.attachShader(this.shaderProgram, r2), this.gl.attachShader(this.shaderProgram, a2), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.warpUvLocation = this.gl.getAttribLocation(this.shaderProgram, "aWarpUv"), this.warpColorLocation = this.gl.getAttribLocation(this.shaderProgram, "aWarpColor"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_main"), this.textureFWLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_fw_main"), this.textureFCLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_fc_main"), this.texturePWLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_pw_main"), this.texturePCLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_pc_main"), this.blurTexture1Loc = this.gl.getUniformLocation(this.shaderProgram, "sampler_blur1"), this.blurTexture2Loc = this.gl.getUniformLocation(this.shaderProgram, "sampler_blur2"), this.blurTexture3Loc = this.gl.getUniformLocation(this.shaderProgram, "sampler_blur3"), this.noiseLQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_lq"), this.noiseMQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_mq"), this.noiseHQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_hq"), this.noiseLQLiteLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_lq_lite"), this.noisePointLQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_pw_noise_lq"), this.noiseVolLQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noisevol_lq"), this.noiseVolHQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noisevol_hq"), this.decayLoc = this.gl.getUniformLocation(this.shaderProgram, "decay"), this.texsizeLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize"), this.texsizeNoiseLQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_lq"), this.texsizeNoiseMQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_mq"), this.texsizeNoiseHQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_hq"), this.texsizeNoiseLQLiteLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_lq_lite"), this.texsizeNoiseVolLQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noisevol_lq"), this.texsizeNoiseVolHQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noisevol_hq"), this.resolutionLoc = this.gl.getUniformLocation(this.shaderProgram, "resolution"), this.aspectLoc = this.gl.getUniformLocation(this.shaderProgram, "aspect"), this.bassLoc = this.gl.getUniformLocation(this.shaderProgram, "bass"), this.midLoc = this.gl.getUniformLocation(this.shaderProgram, "mid"), this.trebLoc = this.gl.getUniformLocation(this.shaderProgram, "treb"), this.volLoc = this.gl.getUniformLocation(this.shaderProgram, "vol"), this.bassAttLoc = this.gl.getUniformLocation(this.shaderProgram, "bass_att"), this.midAttLoc = this.gl.getUniformLocation(this.shaderProgram, "mid_att"), this.trebAttLoc = this.gl.getUniformLocation(this.shaderProgram, "treb_att"), this.volAttLoc = this.gl.getUniformLocation(this.shaderProgram, "vol_att"), this.timeLoc = this.gl.getUniformLocation(this.shaderProgram, "time"), this.frameLoc = this.gl.getUniformLocation(this.shaderProgram, "frame"), this.fpsLoc = this.gl.getUniformLocation(this.shaderProgram, "fps"), this.blur1MinLoc = this.gl.getUniformLocation(this.shaderProgram, "blur1_min"), this.blur1MaxLoc = this.gl.getUniformLocation(this.shaderProgram, "blur1_max"), this.blur2MinLoc = this.gl.getUniformLocation(this.shaderProgram, "blur2_min"), this.blur2MaxLoc = this.gl.getUniformLocation(this.shaderProgram, "blur2_max"), this.blur3MinLoc = this.gl.getUniformLocation(this.shaderProgram, "blur3_min"), this.blur3MaxLoc = this.gl.getUniformLocation(this.shaderProgram, "blur3_max"), this.scale1Loc = this.gl.getUniformLocation(this.shaderProgram, "scale1"), this.scale2Loc = this.gl.getUniformLocation(this.shaderProgram, "scale2"), this.scale3Loc = this.gl.getUniformLocation(this.shaderProgram, "scale3"), this.bias1Loc = this.gl.getUniformLocation(this.shaderProgram, "bias1"), this.bias2Loc = this.gl.getUniformLocation(this.shaderProgram, "bias2"), this.bias3Loc = this.gl.getUniformLocation(this.shaderProgram, "bias3"), this.randPresetLoc = this.gl.getUniformLocation(this.shaderProgram, "rand_preset"), this.randFrameLoc = this.gl.getUniformLocation(this.shaderProgram, "rand_frame"), this.qaLoc = this.gl.getUniformLocation(this.shaderProgram, "_qa"), this.qbLoc = this.gl.getUniformLocation(this.shaderProgram, "_qb"), this.qcLoc = this.gl.getUniformLocation(this.shaderProgram, "_qc"), this.qdLoc = this.gl.getUniformLocation(this.shaderProgram, "_qd"), this.qeLoc = this.gl.getUniformLocation(this.shaderProgram, "_qe"), this.qfLoc = this.gl.getUniformLocation(this.shaderProgram, "_qf"), this.qgLoc = this.gl.getUniformLocation(this.shaderProgram, "_qg"), this.qhLoc = this.gl.getUniformLocation(this.shaderProgram, "_qh"), this.slowRoamCosLoc = this.gl.getUniformLocation(this.shaderProgram, "slow_roam_cos"), this.roamCosLoc = this.gl.getUniformLocation(this.shaderProgram, "roam_cos"), this.slowRoamSinLoc = this.gl.getUniformLocation(this.shaderProgram, "slow_roam_sin"), this.roamSinLoc = this.gl.getUniformLocation(this.shaderProgram, "roam_sin");
              for (var h2 = 0; h2 < this.userTextures.length; h2++) {
                var o2 = this.userTextures[h2];
                o2.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_".concat(o2.sampler));
              }
            } }, { key: "updateShader", value: function(t3) {
              this.createShader(t3);
            } }, { key: "bindBlurVals", value: function(t3, e3) {
              var i3 = t3[0], s3 = t3[1], r2 = t3[2], a2 = e3[0], h2 = e3[1], o2 = e3[2], n2 = a2 - i3, l2 = i3, m2 = h2 - s3, u2 = s3, g2 = o2 - r2, c2 = r2;
              this.gl.uniform1f(this.blur1MinLoc, i3), this.gl.uniform1f(this.blur1MaxLoc, a2), this.gl.uniform1f(this.blur2MinLoc, s3), this.gl.uniform1f(this.blur2MaxLoc, h2), this.gl.uniform1f(this.blur3MinLoc, r2), this.gl.uniform1f(this.blur3MaxLoc, o2), this.gl.uniform1f(this.scale1Loc, n2), this.gl.uniform1f(this.scale2Loc, m2), this.gl.uniform1f(this.scale3Loc, g2), this.gl.uniform1f(this.bias1Loc, l2), this.gl.uniform1f(this.bias2Loc, u2), this.gl.uniform1f(this.bias3Loc, c2);
            } }, { key: "renderQuadTexture", value: function(t3, e3, i3, s3, r2, a2, h2, o2, n2, l2) {
              this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.indexBuf), this.gl.bufferData(this.gl.ELEMENT_ARRAY_BUFFER, this.indices, this.gl.STATIC_DRAW), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.vertices, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.warpUvVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, n2, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.warpUvLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.warpUvLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.warpColorVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, l2, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.warpColorLocation, 4, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.warpColorLocation);
              var m2 = 0 !== o2.wrap ? this.gl.REPEAT : this.gl.CLAMP_TO_EDGE;
              this.gl.samplerParameteri(this.mainSampler, this.gl.TEXTURE_WRAP_S, m2), this.gl.samplerParameteri(this.mainSampler, this.gl.TEXTURE_WRAP_T, m2), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(0, this.mainSampler), this.gl.uniform1i(this.textureLoc, 0), this.gl.activeTexture(this.gl.TEXTURE1), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(1, this.mainSamplerFW), this.gl.uniform1i(this.textureFWLoc, 1), this.gl.activeTexture(this.gl.TEXTURE2), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(2, this.mainSamplerFC), this.gl.uniform1i(this.textureFCLoc, 2), this.gl.activeTexture(this.gl.TEXTURE3), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(3, this.mainSamplerPW), this.gl.uniform1i(this.texturePWLoc, 3), this.gl.activeTexture(this.gl.TEXTURE4), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(4, this.mainSamplerPC), this.gl.uniform1i(this.texturePCLoc, 4), this.gl.activeTexture(this.gl.TEXTURE5), this.gl.bindTexture(this.gl.TEXTURE_2D, i3), this.gl.uniform1i(this.blurTexture1Loc, 5), this.gl.activeTexture(this.gl.TEXTURE6), this.gl.bindTexture(this.gl.TEXTURE_2D, s3), this.gl.uniform1i(this.blurTexture2Loc, 6), this.gl.activeTexture(this.gl.TEXTURE7), this.gl.bindTexture(this.gl.TEXTURE_2D, r2), this.gl.uniform1i(this.blurTexture3Loc, 7), this.gl.activeTexture(this.gl.TEXTURE8), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexLQ), this.gl.uniform1i(this.noiseLQLoc, 8), this.gl.activeTexture(this.gl.TEXTURE9), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexMQ), this.gl.uniform1i(this.noiseMQLoc, 9), this.gl.activeTexture(this.gl.TEXTURE10), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexHQ), this.gl.uniform1i(this.noiseHQLoc, 10), this.gl.activeTexture(this.gl.TEXTURE11), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexLQLite), this.gl.uniform1i(this.noiseLQLiteLoc, 11), this.gl.activeTexture(this.gl.TEXTURE12), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexLQ), this.gl.bindSampler(12, this.noise.noiseTexPointLQ), this.gl.uniform1i(this.noisePointLQLoc, 12), this.gl.activeTexture(this.gl.TEXTURE13), this.gl.bindTexture(this.gl.TEXTURE_3D, this.noise.noiseTexVolLQ), this.gl.uniform1i(this.noiseVolLQLoc, 13), this.gl.activeTexture(this.gl.TEXTURE14), this.gl.bindTexture(this.gl.TEXTURE_3D, this.noise.noiseTexVolHQ), this.gl.uniform1i(this.noiseVolHQLoc, 14);
              for (var u2 = 0; u2 < this.userTextures.length; u2++) {
                var g2 = this.userTextures[u2];
                this.gl.activeTexture(this.gl.TEXTURE15 + u2), this.gl.bindTexture(this.gl.TEXTURE_2D, this.image.getTexture(g2.sampler)), this.gl.uniform1i(g2.textureLoc, 15 + u2);
              }
              this.gl.uniform1f(this.decayLoc, o2.decay), this.gl.uniform2fv(this.resolutionLoc, [this.texsizeX, this.texsizeY]), this.gl.uniform4fv(this.aspectLoc, [this.aspectx, this.aspecty, this.invAspectx, this.invAspecty]), this.gl.uniform4fv(this.texsizeLoc, [this.texsizeX, this.texsizeY, 1 / this.texsizeX, 1 / this.texsizeY]), this.gl.uniform4fv(this.texsizeNoiseLQLoc, [256, 256, 1 / 256, 1 / 256]), this.gl.uniform4fv(this.texsizeNoiseMQLoc, [256, 256, 1 / 256, 1 / 256]), this.gl.uniform4fv(this.texsizeNoiseHQLoc, [256, 256, 1 / 256, 1 / 256]), this.gl.uniform4fv(this.texsizeNoiseLQLiteLoc, [32, 32, 1 / 32, 1 / 32]), this.gl.uniform4fv(this.texsizeNoiseVolLQLoc, [32, 32, 1 / 32, 1 / 32]), this.gl.uniform4fv(this.texsizeNoiseVolHQLoc, [32, 32, 1 / 32, 1 / 32]), this.gl.uniform1f(this.bassLoc, o2.bass), this.gl.uniform1f(this.midLoc, o2.mid), this.gl.uniform1f(this.trebLoc, o2.treb), this.gl.uniform1f(this.volLoc, (o2.bass + o2.mid + o2.treb) / 3), this.gl.uniform1f(this.bassAttLoc, o2.bass_att), this.gl.uniform1f(this.midAttLoc, o2.mid_att), this.gl.uniform1f(this.trebAttLoc, o2.treb_att), this.gl.uniform1f(this.volAttLoc, (o2.bass_att + o2.mid_att + o2.treb_att) / 3), this.gl.uniform1f(this.timeLoc, o2.time), this.gl.uniform1f(this.frameLoc, o2.frame), this.gl.uniform1f(this.fpsLoc, o2.fps), this.gl.uniform4fv(this.randPresetLoc, o2.rand_preset), this.gl.uniform4fv(this.randFrameLoc, new Float32Array([Math.random(), Math.random(), Math.random(), Math.random()])), this.gl.uniform4fv(this.qaLoc, new Float32Array([o2.q1 || 0, o2.q2 || 0, o2.q3 || 0, o2.q4 || 0])), this.gl.uniform4fv(this.qbLoc, new Float32Array([o2.q5 || 0, o2.q6 || 0, o2.q7 || 0, o2.q8 || 0])), this.gl.uniform4fv(this.qcLoc, new Float32Array([o2.q9 || 0, o2.q10 || 0, o2.q11 || 0, o2.q12 || 0])), this.gl.uniform4fv(this.qdLoc, new Float32Array([o2.q13 || 0, o2.q14 || 0, o2.q15 || 0, o2.q16 || 0])), this.gl.uniform4fv(this.qeLoc, new Float32Array([o2.q17 || 0, o2.q18 || 0, o2.q19 || 0, o2.q20 || 0])), this.gl.uniform4fv(this.qfLoc, new Float32Array([o2.q21 || 0, o2.q22 || 0, o2.q23 || 0, o2.q24 || 0])), this.gl.uniform4fv(this.qgLoc, new Float32Array([o2.q25 || 0, o2.q26 || 0, o2.q27 || 0, o2.q28 || 0])), this.gl.uniform4fv(this.qhLoc, new Float32Array([o2.q29 || 0, o2.q30 || 0, o2.q31 || 0, o2.q32 || 0])), this.gl.uniform4fv(this.slowRoamCosLoc, [0.5 + 0.5 * Math.cos(5e-3 * o2.time), 0.5 + 0.5 * Math.cos(8e-3 * o2.time), 0.5 + 0.5 * Math.cos(0.013 * o2.time), 0.5 + 0.5 * Math.cos(0.022 * o2.time)]), this.gl.uniform4fv(this.roamCosLoc, [0.5 + 0.5 * Math.cos(0.3 * o2.time), 0.5 + 0.5 * Math.cos(1.3 * o2.time), 0.5 + 0.5 * Math.cos(5 * o2.time), 0.5 + 0.5 * Math.cos(20 * o2.time)]), this.gl.uniform4fv(this.slowRoamSinLoc, [0.5 + 0.5 * Math.sin(5e-3 * o2.time), 0.5 + 0.5 * Math.sin(8e-3 * o2.time), 0.5 + 0.5 * Math.sin(0.013 * o2.time), 0.5 + 0.5 * Math.sin(0.022 * o2.time)]), this.gl.uniform4fv(this.roamSinLoc, [0.5 + 0.5 * Math.sin(0.3 * o2.time), 0.5 + 0.5 * Math.sin(1.3 * o2.time), 0.5 + 0.5 * Math.sin(5 * o2.time), 0.5 + 0.5 * Math.sin(20 * o2.time)]), this.bindBlurVals(a2, h2), t3 ? this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA) : this.gl.disable(this.gl.BLEND), this.gl.drawElements(this.gl.TRIANGLES, this.indices.length, this.gl.UNSIGNED_SHORT, 0), t3 || this.gl.enable(this.gl.BLEND);
            } }]) && z(e2.prototype, i2), s2 && z(e2, s2), t2;
          })();
          function C(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var D = (function() {
            function t2(e3, i3, s3) {
              var r2 = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {};
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.noise = i3, this.image = s3, this.mesh_width = r2.mesh_width, this.mesh_height = r2.mesh_height, this.texsizeX = r2.texsizeX, this.texsizeY = r2.texsizeY, this.aspectx = r2.aspectx, this.aspecty = r2.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.compWidth = 32, this.compHeight = 24, this.buildPositions(), this.indexBuf = e3.createBuffer(), this.positionVertexBuf = this.gl.createBuffer(), this.compColorVertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader(), this.mainSampler = this.gl.createSampler(), this.mainSamplerFW = this.gl.createSampler(), this.mainSamplerFC = this.gl.createSampler(), this.mainSamplerPW = this.gl.createSampler(), this.mainSamplerPC = this.gl.createSampler(), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_MIN_FILTER, e3.LINEAR_MIPMAP_LINEAR), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_MAG_FILTER, e3.LINEAR), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.mainSampler, e3.TEXTURE_WRAP_T, e3.REPEAT), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_MIN_FILTER, e3.LINEAR_MIPMAP_LINEAR), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_MAG_FILTER, e3.LINEAR), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.mainSamplerFW, e3.TEXTURE_WRAP_T, e3.REPEAT), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_MIN_FILTER, e3.LINEAR_MIPMAP_LINEAR), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_MAG_FILTER, e3.LINEAR), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_WRAP_S, e3.CLAMP_TO_EDGE), e3.samplerParameteri(this.mainSamplerFC, e3.TEXTURE_WRAP_T, e3.CLAMP_TO_EDGE), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_MIN_FILTER, e3.NEAREST_MIPMAP_NEAREST), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_MAG_FILTER, e3.NEAREST), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.mainSamplerPW, e3.TEXTURE_WRAP_T, e3.REPEAT), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_MIN_FILTER, e3.NEAREST_MIPMAP_NEAREST), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_MAG_FILTER, e3.NEAREST), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_WRAP_S, e3.CLAMP_TO_EDGE), e3.samplerParameteri(this.mainSamplerPC, e3.TEXTURE_WRAP_T, e3.CLAMP_TO_EDGE);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "generateHueBase", value: function(t3) {
              for (var e3 = new Float32Array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]), i3 = 0; i3 < 4; i3++) {
                e3[3 * i3 + 0] = 0.6 + 0.3 * Math.sin(30 * t3.time * 0.0143 + 3 + 21 * i3 + t3.rand_start[3]), e3[3 * i3 + 1] = 0.6 + 0.3 * Math.sin(30 * t3.time * 0.0107 + 1 + 13 * i3 + t3.rand_start[1]), e3[3 * i3 + 2] = 0.6 + 0.3 * Math.sin(30 * t3.time * 0.0129 + 6 + 9 * i3 + t3.rand_start[2]);
                for (var s3 = Math.max(e3[3 * i3], e3[3 * i3 + 1], e3[3 * i3 + 2]), r2 = 0; r2 < 3; r2++) e3[3 * i3 + r2] = e3[3 * i3 + r2] / s3, e3[3 * i3 + r2] = 0.5 + 0.5 * e3[3 * i3 + r2];
              }
              return e3;
            } }], (i2 = [{ key: "buildPositions", value: function() {
              for (var t3 = this.compWidth, e3 = this.compHeight, i3 = t3 + 1, s3 = e3 + 1, r2 = 2 / t3, a2 = 2 / e3, h2 = [], o2 = 0; o2 < s3; o2++) for (var n2 = o2 * a2 - 1, l2 = 0; l2 < i3; l2++) {
                var m2 = l2 * r2 - 1;
                h2.push(m2, -n2, 0);
              }
              for (var u2 = [], g2 = 0; g2 < e3; g2++) for (var c2 = 0; c2 < t3; c2++) {
                var A2 = c2 + i3 * g2, f2 = c2 + i3 * (g2 + 1), d2 = c2 + 1 + i3 * (g2 + 1), v2 = c2 + 1 + i3 * g2;
                u2.push(A2, f2, v2), u2.push(f2, d2, v2);
              }
              this.vertices = new Float32Array(h2), this.indices = new Uint16Array(u2);
            } }, { key: "updateGlobals", value: function(t3) {
              this.mesh_width = t3.mesh_width, this.mesh_height = t3.mesh_height, this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.buildPositions();
            } }, { key: "createShader", value: function() {
              var t3, e3, i3 = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : "";
              if (0 === i3.length) t3 = "float orient_horiz = mod(echo_orientation, 2.0);\n                        float orient_x = (orient_horiz != 0.0) ? -1.0 : 1.0;\n                        float orient_y = (echo_orientation >= 2.0) ? -1.0 : 1.0;\n                        vec2 uv_echo = ((uv - 0.5) *\n                                        (1.0 / echo_zoom) *\n                                        vec2(orient_x, orient_y)) + 0.5;\n\n                        ret = mix(texture(sampler_main, uv).rgb,\n                                  texture(sampler_main, uv_echo).rgb,\n                                  echo_alpha);\n\n                        ret *= gammaAdj;\n\n                        if(fShader >= 1.0) {\n                          ret *= hue_shader;\n                        } else if(fShader > 0.001) {\n                          ret *= (1.0 - fShader) + (fShader * hue_shader);\n                        }\n\n                        if(brighten != 0) ret = sqrt(ret);\n                        if(darken != 0) ret = ret*ret;\n                        if(solarize != 0) ret = ret * (1.0 - ret) * 4.0;\n                        if(invert != 0) ret = 1.0 - ret;", e3 = "";
              else {
                var s3 = _.getShaderParts(i3);
                e3 = s3[0], t3 = s3[1];
              }
              t3 = (t3 = t3.replace(/texture2D/g, "texture")).replace(/texture3D/g, "texture"), this.userTextures = _.getUserSamplers(e3), this.shaderProgram = this.gl.createProgram();
              var r2 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(r2, "#version 300 es\n                                      const vec2 halfmad = vec2(0.5);\n                                      in vec2 aPos;\n                                      in vec4 aCompColor;\n                                      out vec2 vUv;\n                                      out vec4 vColor;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos, 0.0, 1.0);\n                                        vUv = aPos * halfmad + halfmad;\n                                        vColor = aCompColor;\n                                      }"), this.gl.compileShader(r2);
              var a2 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(a2, "#version 300 es\n                                      precision ".concat(this.floatPrecision, " float;\n                                      precision highp int;\n                                      precision mediump sampler2D;\n                                      precision mediump sampler3D;\n\n                                      vec3 lum(vec3 v){\n                                          return vec3(dot(v, vec3(0.32,0.49,0.29)));\n                                      }\n\n                                      in vec2 vUv;\n                                      in vec4 vColor;\n                                      out vec4 fragColor;\n                                      uniform sampler2D sampler_main;\n                                      uniform sampler2D sampler_fw_main;\n                                      uniform sampler2D sampler_fc_main;\n                                      uniform sampler2D sampler_pw_main;\n                                      uniform sampler2D sampler_pc_main;\n                                      uniform sampler2D sampler_blur1;\n                                      uniform sampler2D sampler_blur2;\n                                      uniform sampler2D sampler_blur3;\n                                      uniform sampler2D sampler_noise_lq;\n                                      uniform sampler2D sampler_noise_lq_lite;\n                                      uniform sampler2D sampler_noise_mq;\n                                      uniform sampler2D sampler_noise_hq;\n                                      uniform sampler2D sampler_pw_noise_lq;\n                                      uniform sampler3D sampler_noisevol_lq;\n                                      uniform sampler3D sampler_noisevol_hq;\n\n                                      uniform float time;\n                                      uniform float gammaAdj;\n                                      uniform float echo_zoom;\n                                      uniform float echo_alpha;\n                                      uniform float echo_orientation;\n                                      uniform int invert;\n                                      uniform int brighten;\n                                      uniform int darken;\n                                      uniform int solarize;\n                                      uniform vec2 resolution;\n                                      uniform vec4 aspect;\n                                      uniform vec4 texsize;\n                                      uniform vec4 texsize_noise_lq;\n                                      uniform vec4 texsize_noise_mq;\n                                      uniform vec4 texsize_noise_hq;\n                                      uniform vec4 texsize_noise_lq_lite;\n                                      uniform vec4 texsize_noisevol_lq;\n                                      uniform vec4 texsize_noisevol_hq;\n\n                                      uniform float bass;\n                                      uniform float mid;\n                                      uniform float treb;\n                                      uniform float vol;\n                                      uniform float bass_att;\n                                      uniform float mid_att;\n                                      uniform float treb_att;\n                                      uniform float vol_att;\n\n                                      uniform float frame;\n                                      uniform float fps;\n\n                                      uniform vec4 _qa;\n                                      uniform vec4 _qb;\n                                      uniform vec4 _qc;\n                                      uniform vec4 _qd;\n                                      uniform vec4 _qe;\n                                      uniform vec4 _qf;\n                                      uniform vec4 _qg;\n                                      uniform vec4 _qh;\n\n                                      #define q1 _qa.x\n                                      #define q2 _qa.y\n                                      #define q3 _qa.z\n                                      #define q4 _qa.w\n                                      #define q5 _qb.x\n                                      #define q6 _qb.y\n                                      #define q7 _qb.z\n                                      #define q8 _qb.w\n                                      #define q9 _qc.x\n                                      #define q10 _qc.y\n                                      #define q11 _qc.z\n                                      #define q12 _qc.w\n                                      #define q13 _qd.x\n                                      #define q14 _qd.y\n                                      #define q15 _qd.z\n                                      #define q16 _qd.w\n                                      #define q17 _qe.x\n                                      #define q18 _qe.y\n                                      #define q19 _qe.z\n                                      #define q20 _qe.w\n                                      #define q21 _qf.x\n                                      #define q22 _qf.y\n                                      #define q23 _qf.z\n                                      #define q24 _qf.w\n                                      #define q25 _qg.x\n                                      #define q26 _qg.y\n                                      #define q27 _qg.z\n                                      #define q28 _qg.w\n                                      #define q29 _qh.x\n                                      #define q30 _qh.y\n                                      #define q31 _qh.z\n                                      #define q32 _qh.w\n\n                                      uniform vec4 slow_roam_cos;\n                                      uniform vec4 roam_cos;\n                                      uniform vec4 slow_roam_sin;\n                                      uniform vec4 roam_sin;\n\n                                      uniform float blur1_min;\n                                      uniform float blur1_max;\n                                      uniform float blur2_min;\n                                      uniform float blur2_max;\n                                      uniform float blur3_min;\n                                      uniform float blur3_max;\n\n                                      uniform float scale1;\n                                      uniform float scale2;\n                                      uniform float scale3;\n                                      uniform float bias1;\n                                      uniform float bias2;\n                                      uniform float bias3;\n\n                                      uniform vec4 rand_frame;\n                                      uniform vec4 rand_preset;\n\n                                      uniform float fShader;\n\n                                      float PI = ").concat(Math.PI, ";\n\n                                      ").concat(e3, "\n\n                                      void main(void) {\n                                        vec3 ret;\n                                        vec2 uv = vUv;\n                                        vec2 uv_orig = vUv;\n                                        uv.y = 1.0 - uv.y;\n                                        uv_orig.y = 1.0 - uv_orig.y;\n                                        float rad = length(uv - 0.5);\n                                        float ang = atan(uv.x - 0.5, uv.y - 0.5);\n                                        vec3 hue_shader = vColor.rgb;\n\n                                        ").concat(t3, "\n\n                                        fragColor = vec4(ret, vColor.a);\n                                      }")), this.gl.compileShader(a2), this.gl.attachShader(this.shaderProgram, r2), this.gl.attachShader(this.shaderProgram, a2), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.compColorLocation = this.gl.getAttribLocation(this.shaderProgram, "aCompColor"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_main"), this.textureFWLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_fw_main"), this.textureFCLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_fc_main"), this.texturePWLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_pw_main"), this.texturePCLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_pc_main"), this.blurTexture1Loc = this.gl.getUniformLocation(this.shaderProgram, "sampler_blur1"), this.blurTexture2Loc = this.gl.getUniformLocation(this.shaderProgram, "sampler_blur2"), this.blurTexture3Loc = this.gl.getUniformLocation(this.shaderProgram, "sampler_blur3"), this.noiseLQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_lq"), this.noiseMQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_mq"), this.noiseHQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_hq"), this.noiseLQLiteLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noise_lq_lite"), this.noisePointLQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_pw_noise_lq"), this.noiseVolLQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noisevol_lq"), this.noiseVolHQLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_noisevol_hq"), this.timeLoc = this.gl.getUniformLocation(this.shaderProgram, "time"), this.gammaAdjLoc = this.gl.getUniformLocation(this.shaderProgram, "gammaAdj"), this.echoZoomLoc = this.gl.getUniformLocation(this.shaderProgram, "echo_zoom"), this.echoAlphaLoc = this.gl.getUniformLocation(this.shaderProgram, "echo_alpha"), this.echoOrientationLoc = this.gl.getUniformLocation(this.shaderProgram, "echo_orientation"), this.invertLoc = this.gl.getUniformLocation(this.shaderProgram, "invert"), this.brightenLoc = this.gl.getUniformLocation(this.shaderProgram, "brighten"), this.darkenLoc = this.gl.getUniformLocation(this.shaderProgram, "darken"), this.solarizeLoc = this.gl.getUniformLocation(this.shaderProgram, "solarize"), this.texsizeLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize"), this.texsizeNoiseLQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_lq"), this.texsizeNoiseMQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_mq"), this.texsizeNoiseHQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_hq"), this.texsizeNoiseLQLiteLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noise_lq_lite"), this.texsizeNoiseVolLQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noisevol_lq"), this.texsizeNoiseVolHQLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize_noisevol_hq"), this.resolutionLoc = this.gl.getUniformLocation(this.shaderProgram, "resolution"), this.aspectLoc = this.gl.getUniformLocation(this.shaderProgram, "aspect"), this.bassLoc = this.gl.getUniformLocation(this.shaderProgram, "bass"), this.midLoc = this.gl.getUniformLocation(this.shaderProgram, "mid"), this.trebLoc = this.gl.getUniformLocation(this.shaderProgram, "treb"), this.volLoc = this.gl.getUniformLocation(this.shaderProgram, "vol"), this.bassAttLoc = this.gl.getUniformLocation(this.shaderProgram, "bass_att"), this.midAttLoc = this.gl.getUniformLocation(this.shaderProgram, "mid_att"), this.trebAttLoc = this.gl.getUniformLocation(this.shaderProgram, "treb_att"), this.volAttLoc = this.gl.getUniformLocation(this.shaderProgram, "vol_att"), this.frameLoc = this.gl.getUniformLocation(this.shaderProgram, "frame"), this.fpsLoc = this.gl.getUniformLocation(this.shaderProgram, "fps"), this.blur1MinLoc = this.gl.getUniformLocation(this.shaderProgram, "blur1_min"), this.blur1MaxLoc = this.gl.getUniformLocation(this.shaderProgram, "blur1_max"), this.blur2MinLoc = this.gl.getUniformLocation(this.shaderProgram, "blur2_min"), this.blur2MaxLoc = this.gl.getUniformLocation(this.shaderProgram, "blur2_max"), this.blur3MinLoc = this.gl.getUniformLocation(this.shaderProgram, "blur3_min"), this.blur3MaxLoc = this.gl.getUniformLocation(this.shaderProgram, "blur3_max"), this.scale1Loc = this.gl.getUniformLocation(this.shaderProgram, "scale1"), this.scale2Loc = this.gl.getUniformLocation(this.shaderProgram, "scale2"), this.scale3Loc = this.gl.getUniformLocation(this.shaderProgram, "scale3"), this.bias1Loc = this.gl.getUniformLocation(this.shaderProgram, "bias1"), this.bias2Loc = this.gl.getUniformLocation(this.shaderProgram, "bias2"), this.bias3Loc = this.gl.getUniformLocation(this.shaderProgram, "bias3"), this.randPresetLoc = this.gl.getUniformLocation(this.shaderProgram, "rand_preset"), this.randFrameLoc = this.gl.getUniformLocation(this.shaderProgram, "rand_frame"), this.fShaderLoc = this.gl.getUniformLocation(this.shaderProgram, "fShader"), this.qaLoc = this.gl.getUniformLocation(this.shaderProgram, "_qa"), this.qbLoc = this.gl.getUniformLocation(this.shaderProgram, "_qb"), this.qcLoc = this.gl.getUniformLocation(this.shaderProgram, "_qc"), this.qdLoc = this.gl.getUniformLocation(this.shaderProgram, "_qd"), this.qeLoc = this.gl.getUniformLocation(this.shaderProgram, "_qe"), this.qfLoc = this.gl.getUniformLocation(this.shaderProgram, "_qf"), this.qgLoc = this.gl.getUniformLocation(this.shaderProgram, "_qg"), this.qhLoc = this.gl.getUniformLocation(this.shaderProgram, "_qh"), this.slowRoamCosLoc = this.gl.getUniformLocation(this.shaderProgram, "slow_roam_cos"), this.roamCosLoc = this.gl.getUniformLocation(this.shaderProgram, "roam_cos"), this.slowRoamSinLoc = this.gl.getUniformLocation(this.shaderProgram, "slow_roam_sin"), this.roamSinLoc = this.gl.getUniformLocation(this.shaderProgram, "roam_sin");
              for (var h2 = 0; h2 < this.userTextures.length; h2++) {
                var o2 = this.userTextures[h2];
                o2.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "sampler_".concat(o2.sampler));
              }
            } }, { key: "updateShader", value: function(t3) {
              this.createShader(t3);
            } }, { key: "bindBlurVals", value: function(t3, e3) {
              var i3 = t3[0], s3 = t3[1], r2 = t3[2], a2 = e3[0], h2 = e3[1], o2 = e3[2], n2 = a2 - i3, l2 = i3, m2 = h2 - s3, u2 = s3, g2 = o2 - r2, c2 = r2;
              this.gl.uniform1f(this.blur1MinLoc, i3), this.gl.uniform1f(this.blur1MaxLoc, a2), this.gl.uniform1f(this.blur2MinLoc, s3), this.gl.uniform1f(this.blur2MaxLoc, h2), this.gl.uniform1f(this.blur3MinLoc, r2), this.gl.uniform1f(this.blur3MaxLoc, o2), this.gl.uniform1f(this.scale1Loc, n2), this.gl.uniform1f(this.scale2Loc, m2), this.gl.uniform1f(this.scale3Loc, g2), this.gl.uniform1f(this.bias1Loc, l2), this.gl.uniform1f(this.bias2Loc, u2), this.gl.uniform1f(this.bias3Loc, c2);
            } }, { key: "generateCompColors", value: function(e3, i3, s3) {
              for (var r2 = t2.generateHueBase(i3), a2 = this.compWidth + 1, h2 = this.compHeight + 1, o2 = new Float32Array(a2 * h2 * 4), n2 = 0, l2 = 0; l2 < h2; l2++) for (var m2 = 0; m2 < a2; m2++) {
                for (var u2 = m2 / this.compWidth, g2 = l2 / this.compHeight, c2 = [1, 1, 1], A2 = 0; A2 < 3; A2++) c2[A2] = r2[0 + A2] * u2 * g2 + r2[3 + A2] * (1 - u2) * g2 + r2[6 + A2] * u2 * (1 - g2) + r2[9 + A2] * (1 - u2) * (1 - g2);
                var f2 = 1;
                if (e3) {
                  u2 *= this.mesh_width + 1, g2 *= this.mesh_height + 1, u2 = Math.clamp(u2, 0, this.mesh_width - 1), g2 = Math.clamp(g2, 0, this.mesh_height - 1);
                  var d2 = Math.floor(u2), v2 = Math.floor(g2), p2 = u2 - d2, _2 = g2 - v2;
                  f2 = s3[4 * (v2 * (this.mesh_width + 1) + d2) + 3] * (1 - p2) * (1 - _2) + s3[4 * (v2 * (this.mesh_width + 1) + (d2 + 1)) + 3] * p2 * (1 - _2) + s3[4 * ((v2 + 1) * (this.mesh_width + 1) + d2) + 3] * (1 - p2) * _2 + s3[4 * ((v2 + 1) * (this.mesh_width + 1) + (d2 + 1)) + 3] * p2 * _2;
                }
                o2[n2 + 0] = c2[0], o2[n2 + 1] = c2[1], o2[n2 + 2] = c2[2], o2[n2 + 3] = f2, n2 += 4;
              }
              return o2;
            } }, { key: "renderQuadTexture", value: function(t3, e3, i3, s3, r2, a2, h2, o2, n2) {
              var l2 = this.generateCompColors(t3, o2, n2);
              this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.indexBuf), this.gl.bufferData(this.gl.ELEMENT_ARRAY_BUFFER, this.indices, this.gl.STATIC_DRAW), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.vertices, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.compColorVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, l2, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.compColorLocation, 4, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.compColorLocation);
              var m2 = 0 !== o2.wrap ? this.gl.REPEAT : this.gl.CLAMP_TO_EDGE;
              this.gl.samplerParameteri(this.mainSampler, this.gl.TEXTURE_WRAP_S, m2), this.gl.samplerParameteri(this.mainSampler, this.gl.TEXTURE_WRAP_T, m2), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(0, this.mainSampler), this.gl.uniform1i(this.textureLoc, 0), this.gl.activeTexture(this.gl.TEXTURE1), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(1, this.mainSamplerFW), this.gl.uniform1i(this.textureFWLoc, 1), this.gl.activeTexture(this.gl.TEXTURE2), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(2, this.mainSamplerFC), this.gl.uniform1i(this.textureFCLoc, 2), this.gl.activeTexture(this.gl.TEXTURE3), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(3, this.mainSamplerPW), this.gl.uniform1i(this.texturePWLoc, 3), this.gl.activeTexture(this.gl.TEXTURE4), this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.bindSampler(4, this.mainSamplerPC), this.gl.uniform1i(this.texturePCLoc, 4), this.gl.activeTexture(this.gl.TEXTURE5), this.gl.bindTexture(this.gl.TEXTURE_2D, i3), this.gl.uniform1i(this.blurTexture1Loc, 5), this.gl.activeTexture(this.gl.TEXTURE6), this.gl.bindTexture(this.gl.TEXTURE_2D, s3), this.gl.uniform1i(this.blurTexture2Loc, 6), this.gl.activeTexture(this.gl.TEXTURE7), this.gl.bindTexture(this.gl.TEXTURE_2D, r2), this.gl.uniform1i(this.blurTexture3Loc, 7), this.gl.activeTexture(this.gl.TEXTURE8), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexLQ), this.gl.uniform1i(this.noiseLQLoc, 8), this.gl.activeTexture(this.gl.TEXTURE9), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexMQ), this.gl.uniform1i(this.noiseMQLoc, 9), this.gl.activeTexture(this.gl.TEXTURE10), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexHQ), this.gl.uniform1i(this.noiseHQLoc, 10), this.gl.activeTexture(this.gl.TEXTURE11), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexLQLite), this.gl.uniform1i(this.noiseLQLiteLoc, 11), this.gl.activeTexture(this.gl.TEXTURE12), this.gl.bindTexture(this.gl.TEXTURE_2D, this.noise.noiseTexLQ), this.gl.bindSampler(12, this.noise.noiseTexPointLQ), this.gl.uniform1i(this.noisePointLQLoc, 12), this.gl.activeTexture(this.gl.TEXTURE13), this.gl.bindTexture(this.gl.TEXTURE_3D, this.noise.noiseTexVolLQ), this.gl.uniform1i(this.noiseVolLQLoc, 13), this.gl.activeTexture(this.gl.TEXTURE14), this.gl.bindTexture(this.gl.TEXTURE_3D, this.noise.noiseTexVolHQ), this.gl.uniform1i(this.noiseVolHQLoc, 14);
              for (var u2 = 0; u2 < this.userTextures.length; u2++) {
                var g2 = this.userTextures[u2];
                this.gl.activeTexture(this.gl.TEXTURE15 + u2), this.gl.bindTexture(this.gl.TEXTURE_2D, this.image.getTexture(g2.sampler)), this.gl.uniform1i(g2.textureLoc, 15 + u2);
              }
              this.gl.uniform1f(this.timeLoc, o2.time), this.gl.uniform1f(this.gammaAdjLoc, o2.gammaadj), this.gl.uniform1f(this.echoZoomLoc, o2.echo_zoom), this.gl.uniform1f(this.echoAlphaLoc, o2.echo_alpha), this.gl.uniform1f(this.echoOrientationLoc, o2.echo_orient), this.gl.uniform1i(this.invertLoc, o2.invert), this.gl.uniform1i(this.brightenLoc, o2.brighten), this.gl.uniform1i(this.darkenLoc, o2.darken), this.gl.uniform1i(this.solarizeLoc, o2.solarize), this.gl.uniform2fv(this.resolutionLoc, [this.texsizeX, this.texsizeY]), this.gl.uniform4fv(this.aspectLoc, [this.aspectx, this.aspecty, this.invAspectx, this.invAspecty]), this.gl.uniform4fv(this.texsizeLoc, new Float32Array([this.texsizeX, this.texsizeY, 1 / this.texsizeX, 1 / this.texsizeY])), this.gl.uniform4fv(this.texsizeNoiseLQLoc, [256, 256, 1 / 256, 1 / 256]), this.gl.uniform4fv(this.texsizeNoiseMQLoc, [256, 256, 1 / 256, 1 / 256]), this.gl.uniform4fv(this.texsizeNoiseHQLoc, [256, 256, 1 / 256, 1 / 256]), this.gl.uniform4fv(this.texsizeNoiseLQLiteLoc, [32, 32, 1 / 32, 1 / 32]), this.gl.uniform4fv(this.texsizeNoiseVolLQLoc, [32, 32, 1 / 32, 1 / 32]), this.gl.uniform4fv(this.texsizeNoiseVolHQLoc, [32, 32, 1 / 32, 1 / 32]), this.gl.uniform1f(this.bassLoc, o2.bass), this.gl.uniform1f(this.midLoc, o2.mid), this.gl.uniform1f(this.trebLoc, o2.treb), this.gl.uniform1f(this.volLoc, (o2.bass + o2.mid + o2.treb) / 3), this.gl.uniform1f(this.bassAttLoc, o2.bass_att), this.gl.uniform1f(this.midAttLoc, o2.mid_att), this.gl.uniform1f(this.trebAttLoc, o2.treb_att), this.gl.uniform1f(this.volAttLoc, (o2.bass_att + o2.mid_att + o2.treb_att) / 3), this.gl.uniform1f(this.frameLoc, o2.frame), this.gl.uniform1f(this.fpsLoc, o2.fps), this.gl.uniform4fv(this.randPresetLoc, o2.rand_preset), this.gl.uniform4fv(this.randFrameLoc, new Float32Array([Math.random(), Math.random(), Math.random(), Math.random()])), this.gl.uniform1f(this.fShaderLoc, o2.fshader), this.gl.uniform4fv(this.qaLoc, new Float32Array([o2.q1 || 0, o2.q2 || 0, o2.q3 || 0, o2.q4 || 0])), this.gl.uniform4fv(this.qbLoc, new Float32Array([o2.q5 || 0, o2.q6 || 0, o2.q7 || 0, o2.q8 || 0])), this.gl.uniform4fv(this.qcLoc, new Float32Array([o2.q9 || 0, o2.q10 || 0, o2.q11 || 0, o2.q12 || 0])), this.gl.uniform4fv(this.qdLoc, new Float32Array([o2.q13 || 0, o2.q14 || 0, o2.q15 || 0, o2.q16 || 0])), this.gl.uniform4fv(this.qeLoc, new Float32Array([o2.q17 || 0, o2.q18 || 0, o2.q19 || 0, o2.q20 || 0])), this.gl.uniform4fv(this.qfLoc, new Float32Array([o2.q21 || 0, o2.q22 || 0, o2.q23 || 0, o2.q24 || 0])), this.gl.uniform4fv(this.qgLoc, new Float32Array([o2.q25 || 0, o2.q26 || 0, o2.q27 || 0, o2.q28 || 0])), this.gl.uniform4fv(this.qhLoc, new Float32Array([o2.q29 || 0, o2.q30 || 0, o2.q31 || 0, o2.q32 || 0])), this.gl.uniform4fv(this.slowRoamCosLoc, [0.5 + 0.5 * Math.cos(5e-3 * o2.time), 0.5 + 0.5 * Math.cos(8e-3 * o2.time), 0.5 + 0.5 * Math.cos(0.013 * o2.time), 0.5 + 0.5 * Math.cos(0.022 * o2.time)]), this.gl.uniform4fv(this.roamCosLoc, [0.5 + 0.5 * Math.cos(0.3 * o2.time), 0.5 + 0.5 * Math.cos(1.3 * o2.time), 0.5 + 0.5 * Math.cos(5 * o2.time), 0.5 + 0.5 * Math.cos(20 * o2.time)]), this.gl.uniform4fv(this.slowRoamSinLoc, [0.5 + 0.5 * Math.sin(5e-3 * o2.time), 0.5 + 0.5 * Math.sin(8e-3 * o2.time), 0.5 + 0.5 * Math.sin(0.013 * o2.time), 0.5 + 0.5 * Math.sin(0.022 * o2.time)]), this.gl.uniform4fv(this.roamSinLoc, [0.5 + 0.5 * Math.sin(0.3 * o2.time), 0.5 + 0.5 * Math.sin(1.3 * o2.time), 0.5 + 0.5 * Math.sin(5 * o2.time), 0.5 + 0.5 * Math.sin(20 * o2.time)]), this.bindBlurVals(a2, h2), t3 ? this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA) : this.gl.disable(this.gl.BLEND), this.gl.drawElements(this.gl.TRIANGLES, this.indices.length, this.gl.UNSIGNED_SHORT, 0), t3 || this.gl.enable(this.gl.BLEND);
            } }]) && C(e2.prototype, i2), s2 && C(e2, s2), t2;
          })();
          function V(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var I = (function() {
            function t2(e3, i3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.textureRatio = i3.textureRatio, this.texsizeX = i3.texsizeX, this.texsizeY = i3.texsizeY, this.positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), this.vertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.useFXAA() ? this.createFXAAShader() : this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "useFXAA", value: function() {
              return this.textureRatio <= 1;
            } }, { key: "updateGlobals", value: function(t3) {
              this.textureRatio = t3.textureRatio, this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.gl.deleteProgram(this.shaderProgram), this.useFXAA() ? this.createFXAAShader() : this.createShader();
            } }, { key: "createFXAAShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n       const vec2 halfmad = vec2(0.5);\n       in vec2 aPos;\n       out vec2 v_rgbM;\n       out vec2 v_rgbNW;\n       out vec2 v_rgbNE;\n       out vec2 v_rgbSW;\n       out vec2 v_rgbSE;\n       uniform vec4 texsize;\n       void main(void) {\n         gl_Position = vec4(aPos, 0.0, 1.0);\n\n         v_rgbM = aPos * halfmad + halfmad;\n         v_rgbNW = v_rgbM + (vec2(-1.0, -1.0) * texsize.zx);\n         v_rgbNE = v_rgbM + (vec2(1.0, -1.0) * texsize.zx);\n         v_rgbSW = v_rgbM + (vec2(-1.0, 1.0) * texsize.zx);\n         v_rgbSE = v_rgbM + (vec2(1.0, 1.0) * texsize.zx);\n       }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n       precision ".concat(this.floatPrecision, " float;\n       precision highp int;\n       precision mediump sampler2D;\n\n       in vec2 v_rgbM;\n       in vec2 v_rgbNW;\n       in vec2 v_rgbNE;\n       in vec2 v_rgbSW;\n       in vec2 v_rgbSE;\n       out vec4 fragColor;\n       uniform vec4 texsize;\n       uniform sampler2D uTexture;\n\n       #ifndef FXAA_REDUCE_MIN\n         #define FXAA_REDUCE_MIN   (1.0/ 128.0)\n       #endif\n       #ifndef FXAA_REDUCE_MUL\n         #define FXAA_REDUCE_MUL   (1.0 / 8.0)\n       #endif\n       #ifndef FXAA_SPAN_MAX\n         #define FXAA_SPAN_MAX     8.0\n       #endif\n\n       void main(void) {\n         vec4 color;\n         vec3 rgbNW = textureLod(uTexture, v_rgbNW, 0.0).xyz;\n         vec3 rgbNE = textureLod(uTexture, v_rgbNE, 0.0).xyz;\n         vec3 rgbSW = textureLod(uTexture, v_rgbSW, 0.0).xyz;\n         vec3 rgbSE = textureLod(uTexture, v_rgbSE, 0.0).xyz;\n         vec3 rgbM  = textureLod(uTexture, v_rgbM, 0.0).xyz;\n         vec3 luma = vec3(0.299, 0.587, 0.114);\n         float lumaNW = dot(rgbNW, luma);\n         float lumaNE = dot(rgbNE, luma);\n         float lumaSW = dot(rgbSW, luma);\n         float lumaSE = dot(rgbSE, luma);\n         float lumaM  = dot(rgbM,  luma);\n         float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));\n         float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));\n\n         mediump vec2 dir;\n         dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));\n         dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));\n\n         float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *\n                               (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);\n\n         float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);\n         dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),\n                   max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),\n                   dir * rcpDirMin)) * texsize.zw;\n\n         vec3 rgbA = 0.5 * (\n             textureLod(uTexture, v_rgbM + dir * (1.0 / 3.0 - 0.5), 0.0).xyz +\n             textureLod(uTexture, v_rgbM + dir * (2.0 / 3.0 - 0.5), 0.0).xyz);\n         vec3 rgbB = rgbA * 0.5 + 0.25 * (\n             textureLod(uTexture, v_rgbM + dir * -0.5, 0.0).xyz +\n             textureLod(uTexture, v_rgbM + dir * 0.5, 0.0).xyz);\n\n         float lumaB = dot(rgbB, luma);\n         if ((lumaB < lumaMin) || (lumaB > lumaMax))\n           color = vec4(rgbA, 1.0);\n         else\n           color = vec4(rgbB, 1.0);\n\n         fragColor = color;\n       }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture"), this.texsizeLoc = this.gl.getUniformLocation(this.shaderProgram, "texsize");
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n       const vec2 halfmad = vec2(0.5);\n       in vec2 aPos;\n       out vec2 uv;\n       void main(void) {\n         gl_Position = vec4(aPos, 0.0, 1.0);\n         uv = aPos * halfmad + halfmad;\n       }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n       precision ".concat(this.floatPrecision, " float;\n       precision highp int;\n       precision mediump sampler2D;\n\n       in vec2 uv;\n       out vec4 fragColor;\n       uniform sampler2D uTexture;\n\n       void main(void) {\n         fragColor = vec4(texture(uTexture, uv).rgb, 1.0);\n       }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture");
            } }, { key: "renderQuadTexture", value: function(t3) {
              this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.uniform1i(this.textureLoc, 0), this.useFXAA() && this.gl.uniform4fv(this.texsizeLoc, new Float32Array([this.texsizeX, this.texsizeY, 1 / this.texsizeX, 1 / this.texsizeY])), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLE_STRIP, 0, 4);
            } }]) && V(e2.prototype, i2), s2 && V(e2, s2), t2;
          })();
          function X(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var k = (function() {
            function t2(e3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), this.vertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n       const vec2 halfmad = vec2(0.5);\n       in vec2 aPos;\n       out vec2 uv;\n       void main(void) {\n         gl_Position = vec4(aPos, 0.0, 1.0);\n         uv = aPos * halfmad + halfmad;\n       }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n       precision ".concat(this.floatPrecision, " float;\n       precision highp int;\n       precision mediump sampler2D;\n\n       in vec2 uv;\n       out vec4 fragColor;\n       uniform sampler2D uTexture;\n\n       void main(void) {\n         fragColor = vec4(texture(uTexture, uv).rgb, 1.0);\n       }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture");
            } }, { key: "renderQuadTexture", value: function(t3) {
              this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.gl.uniform1i(this.textureLoc, 0), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLE_STRIP, 0, 4);
            } }]) && X(e2.prototype, i2), s2 && X(e2, s2), t2;
          })();
          function N(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var O = (function() {
            function t2(e3, i3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.blurLevel = i3;
              var s3 = [4, 3.8, 3.5, 2.9, 1.9, 1.2, 0.7, 0.3], r2 = s3[0] + s3[1] + s3[2] + s3[3], a2 = s3[4] + s3[5] + s3[6] + s3[7], h2 = 0 + (s3[2] + s3[3]) / r2 * 2, o2 = 2 + (s3[6] + s3[7]) / a2 * 2;
              this.wds = new Float32Array([r2, a2, h2, o2]), this.wDiv = 1 / (2 * (r2 + a2)), this.positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), this.vertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      const vec2 halfmad = vec2(0.5);\n                                      in vec2 aPos;\n                                      out vec2 uv;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos, 0.0, 1.0);\n                                        uv = aPos * halfmad + halfmad;\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n       precision ".concat(this.floatPrecision, " float;\n       precision highp int;\n       precision mediump sampler2D;\n\n       in vec2 uv;\n       out vec4 fragColor;\n       uniform sampler2D uTexture;\n       uniform vec4 texsize;\n       uniform float ed1;\n       uniform float ed2;\n       uniform float ed3;\n       uniform vec4 wds;\n       uniform float wdiv;\n\n       void main(void) {\n         float w1 = wds[0];\n         float w2 = wds[1];\n         float d1 = wds[2];\n         float d2 = wds[3];\n\n         vec2 uv2 = uv.xy;\n\n         vec3 blur =\n           ( texture(uTexture, uv2 + vec2(0.0, d1 * texsize.w) ).xyz\n           + texture(uTexture, uv2 + vec2(0.0,-d1 * texsize.w) ).xyz) * w1 +\n           ( texture(uTexture, uv2 + vec2(0.0, d2 * texsize.w) ).xyz\n           + texture(uTexture, uv2 + vec2(0.0,-d2 * texsize.w) ).xyz) * w2;\n\n         blur.xyz *= wdiv;\n\n         float t = min(min(uv.x, uv.y), 1.0 - max(uv.x, uv.y));\n         t = sqrt(t);\n         t = ed1 + ed2 * clamp(t * ed3, 0.0, 1.0);\n         blur.xyz *= t;\n\n         fragColor = vec4(blur, 1.0);\n       }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture"), this.texsizeLocation = this.gl.getUniformLocation(this.shaderProgram, "texsize"), this.ed1Loc = this.gl.getUniformLocation(this.shaderProgram, "ed1"), this.ed2Loc = this.gl.getUniformLocation(this.shaderProgram, "ed2"), this.ed3Loc = this.gl.getUniformLocation(this.shaderProgram, "ed3"), this.wdsLocation = this.gl.getUniformLocation(this.shaderProgram, "wds"), this.wdivLoc = this.gl.getUniformLocation(this.shaderProgram, "wdiv");
            } }, { key: "renderQuadTexture", value: function(t3, e3, i3) {
              this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.uniform1i(this.textureLoc, 0);
              var s3 = 0 === this.blurLevel ? e3.b1ed : 0;
              this.gl.uniform4fv(this.texsizeLocation, [i3[0], i3[1], 1 / i3[0], 1 / i3[1]]), this.gl.uniform1f(this.ed1Loc, 1 - s3), this.gl.uniform1f(this.ed2Loc, s3), this.gl.uniform1f(this.ed3Loc, 5), this.gl.uniform4fv(this.wdsLocation, this.wds), this.gl.uniform1f(this.wdivLoc, this.wDiv), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLE_STRIP, 0, 4);
            } }]) && N(e2.prototype, i2), s2 && N(e2, s2), t2;
          })();
          function W(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var Q = (function() {
            function t2(e3, i3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.blurLevel = i3;
              var s3 = [4, 3.8, 3.5, 2.9, 1.9, 1.2, 0.7, 0.3], r2 = s3[0] + s3[1], a2 = s3[2] + s3[3], h2 = s3[4] + s3[5], o2 = s3[6] + s3[7], n2 = 0 + 2 * s3[1] / r2, l2 = 2 + 2 * s3[3] / a2, m2 = 4 + 2 * s3[5] / h2, u2 = 6 + 2 * s3[7] / o2;
              this.ws = new Float32Array([r2, a2, h2, o2]), this.ds = new Float32Array([n2, l2, m2, u2]), this.wDiv = 0.5 / (r2 + a2 + h2 + o2), this.positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), this.vertexBuf = this.gl.createBuffer(), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n                                      const vec2 halfmad = vec2(0.5);\n                                      in vec2 aPos;\n                                      out vec2 uv;\n                                      void main(void) {\n                                        gl_Position = vec4(aPos, 0.0, 1.0);\n                                        uv = aPos * halfmad + halfmad;\n                                      }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n       precision ".concat(this.floatPrecision, " float;\n       precision highp int;\n       precision mediump sampler2D;\n\n       in vec2 uv;\n       out vec4 fragColor;\n       uniform sampler2D uTexture;\n       uniform vec4 texsize;\n       uniform float scale;\n       uniform float bias;\n       uniform vec4 ws;\n       uniform vec4 ds;\n       uniform float wdiv;\n\n       void main(void) {\n         float w1 = ws[0];\n         float w2 = ws[1];\n         float w3 = ws[2];\n         float w4 = ws[3];\n         float d1 = ds[0];\n         float d2 = ds[1];\n         float d3 = ds[2];\n         float d4 = ds[3];\n\n         vec2 uv2 = uv.xy;\n\n         vec3 blur =\n           ( texture(uTexture, uv2 + vec2( d1 * texsize.z,0.0) ).xyz\n           + texture(uTexture, uv2 + vec2(-d1 * texsize.z,0.0) ).xyz) * w1 +\n           ( texture(uTexture, uv2 + vec2( d2 * texsize.z,0.0) ).xyz\n           + texture(uTexture, uv2 + vec2(-d2 * texsize.z,0.0) ).xyz) * w2 +\n           ( texture(uTexture, uv2 + vec2( d3 * texsize.z,0.0) ).xyz\n           + texture(uTexture, uv2 + vec2(-d3 * texsize.z,0.0) ).xyz) * w3 +\n           ( texture(uTexture, uv2 + vec2( d4 * texsize.z,0.0) ).xyz\n           + texture(uTexture, uv2 + vec2(-d4 * texsize.z,0.0) ).xyz) * w4;\n\n         blur.xyz *= wdiv;\n         blur.xyz = blur.xyz * scale + bias;\n\n         fragColor = vec4(blur, 1.0);\n       }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture"), this.texsizeLocation = this.gl.getUniformLocation(this.shaderProgram, "texsize"), this.scaleLoc = this.gl.getUniformLocation(this.shaderProgram, "scale"), this.biasLoc = this.gl.getUniformLocation(this.shaderProgram, "bias"), this.wsLoc = this.gl.getUniformLocation(this.shaderProgram, "ws"), this.dsLocation = this.gl.getUniformLocation(this.shaderProgram, "ds"), this.wdivLoc = this.gl.getUniformLocation(this.shaderProgram, "wdiv");
            } }, { key: "getScaleAndBias", value: function(t3, e3) {
              var i3, s3, r2 = [1, 1, 1], a2 = [0, 0, 0];
              return r2[0] = 1 / (e3[0] - t3[0]), a2[0] = -t3[0] * r2[0], i3 = (t3[1] - t3[0]) / (e3[0] - t3[0]), s3 = (e3[1] - t3[0]) / (e3[0] - t3[0]), r2[1] = 1 / (s3 - i3), a2[1] = -i3 * r2[1], i3 = (t3[2] - t3[1]) / (e3[1] - t3[1]), s3 = (e3[2] - t3[1]) / (e3[1] - t3[1]), r2[2] = 1 / (s3 - i3), a2[2] = -i3 * r2[2], { scale: r2[this.blurLevel], bias: a2[this.blurLevel] };
            } }, { key: "renderQuadTexture", value: function(t3, e3, i3, s3, r2) {
              this.gl.useProgram(this.shaderProgram), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.positions, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.uniform1i(this.textureLoc, 0);
              var a2 = this.getScaleAndBias(i3, s3), h2 = a2.scale, o2 = a2.bias;
              this.gl.uniform4fv(this.texsizeLocation, [r2[0], r2[1], 1 / r2[0], 1 / r2[1]]), this.gl.uniform1f(this.scaleLoc, h2), this.gl.uniform1f(this.biasLoc, o2), this.gl.uniform4fv(this.wsLoc, this.ws), this.gl.uniform4fv(this.dsLocation, this.ds), this.gl.uniform1f(this.wdivLoc, this.wDiv), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawArrays(this.gl.TRIANGLE_STRIP, 0, 4);
            } }]) && W(e2.prototype, i2), s2 && W(e2, s2), t2;
          })();
          function Y(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var G = (function() {
            function t2(e3, i3, s3) {
              var r2 = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {};
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.blurLevel = e3, this.blurRatios = i3, this.gl = s3, this.texsizeX = r2.texsizeX, this.texsizeY = r2.texsizeY, this.anisoExt = this.gl.getExtension("EXT_texture_filter_anisotropic") || this.gl.getExtension("MOZ_EXT_texture_filter_anisotropic") || this.gl.getExtension("WEBKIT_EXT_texture_filter_anisotropic"), this.blurHorizontalFrameBuffer = this.gl.createFramebuffer(), this.blurVerticalFrameBuffer = this.gl.createFramebuffer(), this.blurHorizontalTexture = this.gl.createTexture(), this.blurVerticalTexture = this.gl.createTexture(), this.setupFrameBufferTextures(), this.blurHorizontal = new Q(s3, this.blurLevel, r2), this.blurVertical = new O(s3, this.blurLevel, r2);
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.setupFrameBufferTextures();
            } }, { key: "getTextureSize", value: function(t3) {
              var e3 = Math.max(this.texsizeX * t3, 16);
              e3 = 16 * Math.floor((e3 + 3) / 16);
              var i3 = Math.max(this.texsizeY * t3, 16);
              return [e3, i3 = 4 * Math.floor((i3 + 3) / 4)];
            } }, { key: "setupFrameBufferTextures", value: function() {
              var t3 = this.blurLevel > 0 ? this.blurRatios[this.blurLevel - 1] : [1, 1], e3 = this.blurRatios[this.blurLevel], i3 = this.getTextureSize(t3[1]), s3 = this.getTextureSize(e3[0]);
              this.bindFrameBufferTexture(this.blurHorizontalFrameBuffer, this.blurHorizontalTexture, s3);
              var r2 = s3, a2 = this.getTextureSize(e3[1]);
              this.bindFrameBufferTexture(this.blurVerticalFrameBuffer, this.blurVerticalTexture, a2), this.horizontalTexsizes = [i3, s3], this.verticalTexsizes = [r2, a2];
            } }, { key: "bindFrambufferAndSetViewport", value: function(t3, e3) {
              this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, t3), this.gl.viewport(0, 0, e3[0], e3[1]);
            } }, { key: "bindFrameBufferTexture", value: function(t3, e3, i3) {
              if (this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.pixelStorei(this.gl.UNPACK_ALIGNMENT, 1), this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, i3[0], i3[1], 0, this.gl.RGBA, this.gl.UNSIGNED_BYTE, new Uint8Array(i3[0] * i3[1] * 4)), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR_MIPMAP_LINEAR), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR), this.anisoExt) {
                var s3 = this.gl.getParameter(this.anisoExt.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
                this.gl.texParameterf(this.gl.TEXTURE_2D, this.anisoExt.TEXTURE_MAX_ANISOTROPY_EXT, s3);
              }
              this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, t3), this.gl.framebufferTexture2D(this.gl.FRAMEBUFFER, this.gl.COLOR_ATTACHMENT0, this.gl.TEXTURE_2D, e3, 0);
            } }, { key: "renderBlurTexture", value: function(t3, e3, i3, s3) {
              this.bindFrambufferAndSetViewport(this.blurHorizontalFrameBuffer, this.horizontalTexsizes[1]), this.blurHorizontal.renderQuadTexture(t3, e3, i3, s3, this.horizontalTexsizes[0]), this.gl.bindTexture(this.gl.TEXTURE_2D, this.blurHorizontalTexture), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.bindFrambufferAndSetViewport(this.blurVerticalFrameBuffer, this.verticalTexsizes[1]), this.blurVertical.renderQuadTexture(this.blurHorizontalTexture, e3, this.verticalTexsizes[0]), this.gl.bindTexture(this.gl.TEXTURE_2D, this.blurVerticalTexture), this.gl.generateMipmap(this.gl.TEXTURE_2D);
            } }]) && Y(e2.prototype, i2), s2 && Y(e2, s2), t2;
          })();
          function H(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var j = (function() {
            function t2(e3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.anisoExt = this.gl.getExtension("EXT_texture_filter_anisotropic") || this.gl.getExtension("MOZ_EXT_texture_filter_anisotropic") || this.gl.getExtension("WEBKIT_EXT_texture_filter_anisotropic"), this.noiseTexLQ = this.gl.createTexture(), this.noiseTexLQLite = this.gl.createTexture(), this.noiseTexMQ = this.gl.createTexture(), this.noiseTexHQ = this.gl.createTexture(), this.noiseTexVolLQ = this.gl.createTexture(), this.noiseTexVolHQ = this.gl.createTexture(), this.nTexArrLQ = t2.createNoiseTex(256, 1), this.nTexArrLQLite = t2.createNoiseTex(32, 1), this.nTexArrMQ = t2.createNoiseTex(256, 4), this.nTexArrHQ = t2.createNoiseTex(256, 8), this.nTexArrVolLQ = t2.createNoiseVolTex(32, 1), this.nTexArrVolHQ = t2.createNoiseVolTex(32, 4), this.bindTexture(this.noiseTexLQ, this.nTexArrLQ, 256, 256), this.bindTexture(this.noiseTexLQLite, this.nTexArrLQLite, 32, 32), this.bindTexture(this.noiseTexMQ, this.nTexArrMQ, 256, 256), this.bindTexture(this.noiseTexHQ, this.nTexArrHQ, 256, 256), this.bindTexture3D(this.noiseTexVolLQ, this.nTexArrVolLQ, 32, 32, 32), this.bindTexture3D(this.noiseTexVolHQ, this.nTexArrVolHQ, 32, 32, 32), this.noiseTexPointLQ = this.gl.createSampler(), e3.samplerParameteri(this.noiseTexPointLQ, e3.TEXTURE_MIN_FILTER, e3.NEAREST_MIPMAP_NEAREST), e3.samplerParameteri(this.noiseTexPointLQ, e3.TEXTURE_MAG_FILTER, e3.NEAREST), e3.samplerParameteri(this.noiseTexPointLQ, e3.TEXTURE_WRAP_S, e3.REPEAT), e3.samplerParameteri(this.noiseTexPointLQ, e3.TEXTURE_WRAP_T, e3.REPEAT);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "fCubicInterpolate", value: function(t3, e3, i3, s3, r2) {
              var a2 = r2 * r2, h2 = s3 - i3 - t3 + e3;
              return h2 * (r2 * a2) + (t3 - e3 - h2) * a2 + (i3 - t3) * r2 + e3;
            } }, { key: "dwCubicInterpolate", value: function(e3, i3, s3, r2, a2) {
              for (var h2 = [], o2 = 0; o2 < 4; o2++) {
                var n2 = t2.fCubicInterpolate(e3[o2] / 255, i3[o2] / 255, s3[o2] / 255, r2[o2] / 255, a2);
                n2 = Math.clamp(n2, 0, 1), h2[o2] = 255 * n2;
              }
              return h2;
            } }, { key: "createNoiseVolTex", value: function(e3, i3) {
              for (var s3 = e3 * e3 * e3, r2 = new Uint8Array(4 * s3), a2 = i3 > 1 ? 216 : 256, h2 = 0.5 * a2, o2 = 0; o2 < s3; o2++) r2[4 * o2 + 0] = Math.floor(Math.random() * a2 + h2), r2[4 * o2 + 1] = Math.floor(Math.random() * a2 + h2), r2[4 * o2 + 2] = Math.floor(Math.random() * a2 + h2), r2[4 * o2 + 3] = Math.floor(Math.random() * a2 + h2);
              var n2 = e3 * e3, l2 = e3;
              if (i3 > 1) {
                for (var m2 = 0; m2 < e3; m2 += i3) for (var u2 = 0; u2 < e3; u2 += i3) for (var g2 = 0; g2 < e3; g2++) if (g2 % i3 != 0) {
                  for (var c2 = Math.floor(g2 / i3) * i3 + e3, A2 = m2 * n2 + u2 * l2, f2 = [], d2 = [], v2 = [], p2 = [], _2 = 0; _2 < 4; _2++) f2[_2] = r2[4 * A2 + (c2 - i3) % e3 * 4 + _2], d2[_2] = r2[4 * A2 + c2 % e3 * 4 + _2], v2[_2] = r2[4 * A2 + (c2 + i3) % e3 * 4 + _2], p2[_2] = r2[4 * A2 + (c2 + 2 * i3) % e3 * 4 + _2];
                  for (var x2 = g2 % i3 / i3, b2 = t2.dwCubicInterpolate(f2, d2, v2, p2, x2), T2 = 0; T2 < 4; T2++) {
                    r2[m2 * n2 * 4 + u2 * l2 * 4 + (4 * g2 + T2)] = b2[T2];
                  }
                }
                for (var E2 = 0; E2 < e3; E2 += i3) for (var P2 = 0; P2 < e3; P2++) for (var R2 = 0; R2 < e3; R2++) if (R2 % i3 != 0) {
                  for (var L2 = Math.floor(R2 / i3) * i3 + e3, S2 = E2 * n2, y2 = [], w2 = [], U2 = [], M2 = [], F2 = 0; F2 < 4; F2++) {
                    var q2 = 4 * P2 + 4 * S2 + F2;
                    y2[F2] = r2[(L2 - i3) % e3 * l2 * 4 + q2], w2[F2] = r2[L2 % e3 * l2 * 4 + q2], U2[F2] = r2[(L2 + i3) % e3 * l2 * 4 + q2], M2[F2] = r2[(L2 + 2 * i3) % e3 * l2 * 4 + q2];
                  }
                  for (var z2 = R2 % i3 / i3, B2 = t2.dwCubicInterpolate(y2, w2, U2, M2, z2), C2 = 0; C2 < 4; C2++) {
                    r2[R2 * l2 * 4 + (4 * P2 + 4 * S2 + C2)] = B2[C2];
                  }
                }
                for (var D2 = 0; D2 < e3; D2++) for (var V2 = 0; V2 < e3; V2++) for (var I2 = 0; I2 < e3; I2++) if (I2 % i3 != 0) {
                  for (var X2 = V2 * l2, k2 = Math.floor(I2 / i3) * i3 + e3, N2 = [], O2 = [], W2 = [], Q2 = [], Y2 = 0; Y2 < 4; Y2++) {
                    var G2 = 4 * D2 + 4 * X2 + Y2;
                    N2[Y2] = r2[(k2 - i3) % e3 * n2 * 4 + G2], O2[Y2] = r2[k2 % e3 * n2 * 4 + G2], W2[Y2] = r2[(k2 + i3) % e3 * n2 * 4 + G2], Q2[Y2] = r2[(k2 + 2 * i3) % e3 * n2 * 4 + G2];
                  }
                  for (var H2 = V2 % i3 / i3, j2 = t2.dwCubicInterpolate(N2, O2, W2, Q2, H2), K2 = 0; K2 < 4; K2++) {
                    r2[I2 * n2 * 4 + (4 * D2 + 4 * X2 + K2)] = j2[K2];
                  }
                }
              }
              return r2;
            } }, { key: "createNoiseTex", value: function(e3, i3) {
              for (var s3 = e3 * e3, r2 = new Uint8Array(4 * s3), a2 = i3 > 1 ? 216 : 256, h2 = 0.5 * a2, o2 = 0; o2 < s3; o2++) r2[4 * o2 + 0] = Math.floor(Math.random() * a2 + h2), r2[4 * o2 + 1] = Math.floor(Math.random() * a2 + h2), r2[4 * o2 + 2] = Math.floor(Math.random() * a2 + h2), r2[4 * o2 + 3] = Math.floor(Math.random() * a2 + h2);
              if (i3 > 1) {
                for (var n2 = 0; n2 < e3; n2 += i3) for (var l2 = 0; l2 < e3; l2++) if (l2 % i3 != 0) {
                  for (var m2 = Math.floor(l2 / i3) * i3 + e3, u2 = n2 * e3, g2 = [], c2 = [], A2 = [], f2 = [], d2 = 0; d2 < 4; d2++) g2[d2] = r2[4 * u2 + (m2 - i3) % e3 * 4 + d2], c2[d2] = r2[4 * u2 + m2 % e3 * 4 + d2], A2[d2] = r2[4 * u2 + (m2 + i3) % e3 * 4 + d2], f2[d2] = r2[4 * u2 + (m2 + 2 * i3) % e3 * 4 + d2];
                  for (var v2 = l2 % i3 / i3, p2 = t2.dwCubicInterpolate(g2, c2, A2, f2, v2), _2 = 0; _2 < 4; _2++) r2[n2 * e3 * 4 + 4 * l2 + _2] = p2[_2];
                }
                for (var x2 = 0; x2 < e3; x2++) for (var b2 = 0; b2 < e3; b2++) if (b2 % i3 != 0) {
                  for (var T2 = Math.floor(b2 / i3) * i3 + e3, E2 = [], P2 = [], R2 = [], L2 = [], S2 = 0; S2 < 4; S2++) E2[S2] = r2[(T2 - i3) % e3 * e3 * 4 + 4 * x2 + S2], P2[S2] = r2[T2 % e3 * e3 * 4 + 4 * x2 + S2], R2[S2] = r2[(T2 + i3) % e3 * e3 * 4 + 4 * x2 + S2], L2[S2] = r2[(T2 + 2 * i3) % e3 * e3 * 4 + 4 * x2 + S2];
                  for (var y2 = b2 % i3 / i3, w2 = t2.dwCubicInterpolate(E2, P2, R2, L2, y2), U2 = 0; U2 < 4; U2++) r2[b2 * e3 * 4 + 4 * x2 + U2] = w2[U2];
                }
              }
              return r2;
            } }], (i2 = [{ key: "bindTexture", value: function(t3, e3, i3, s3) {
              if (this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.pixelStorei(this.gl.UNPACK_ALIGNMENT, 1), this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, i3, s3, 0, this.gl.RGBA, this.gl.UNSIGNED_BYTE, e3), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR_MIPMAP_LINEAR), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR), this.anisoExt) {
                var r2 = this.gl.getParameter(this.anisoExt.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
                this.gl.texParameterf(this.gl.TEXTURE_2D, this.anisoExt.TEXTURE_MAX_ANISOTROPY_EXT, r2);
              }
            } }, { key: "bindTexture3D", value: function(t3, e3, i3, s3, r2) {
              if (this.gl.bindTexture(this.gl.TEXTURE_3D, t3), this.gl.pixelStorei(this.gl.UNPACK_ALIGNMENT, 1), this.gl.texImage3D(this.gl.TEXTURE_3D, 0, this.gl.RGBA, i3, s3, r2, 0, this.gl.RGBA, this.gl.UNSIGNED_BYTE, e3), this.gl.generateMipmap(this.gl.TEXTURE_3D), this.gl.texParameteri(this.gl.TEXTURE_3D, this.gl.TEXTURE_WRAP_S, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_3D, this.gl.TEXTURE_WRAP_T, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_3D, this.gl.TEXTURE_WRAP_R, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_3D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR_MIPMAP_LINEAR), this.gl.texParameteri(this.gl.TEXTURE_3D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR), this.anisoExt) {
                var a2 = this.gl.getParameter(this.anisoExt.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
                this.gl.texParameterf(this.gl.TEXTURE_3D, this.anisoExt.TEXTURE_MAX_ANISOTROPY_EXT, a2);
              }
            } }]) && H(e2.prototype, i2), s2 && H(e2, s2), t2;
          })();
          function K(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var J = (function() {
            function t2(e3) {
              var i3 = this;
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.anisoExt = this.gl.getExtension("EXT_texture_filter_anisotropic") || this.gl.getExtension("MOZ_EXT_texture_filter_anisotropic") || this.gl.getExtension("WEBKIT_EXT_texture_filter_anisotropic"), this.samplers = {}, this.clouds2Image = new Image(), this.clouds2Image.onload = function() {
                i3.samplers.clouds2 = i3.gl.createTexture(), i3.bindTexture(i3.samplers.clouds2, i3.clouds2Image, 128, 128);
              }, this.clouds2Image.src = "data:image/jpeg;base64,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", this.emptyImage = new Image(), this.emptyImage.onload = function() {
                i3.samplers.empty = i3.gl.createTexture(), i3.bindTexture(i3.samplers.empty, i3.emptyImage, 1, 1);
              }, this.emptyImage.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAUEBAAAACwAAAAAAQABAAACAkQBADs=";
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "bindTexture", value: function(t3, e3, i3, s3) {
              if (this.gl.bindTexture(this.gl.TEXTURE_2D, t3), this.gl.pixelStorei(this.gl.UNPACK_ALIGNMENT, 1), this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, i3, s3, 0, this.gl.RGBA, this.gl.UNSIGNED_BYTE, e3), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.REPEAT), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR_MIPMAP_LINEAR), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR), this.anisoExt) {
                var r2 = this.gl.getParameter(this.anisoExt.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
                this.gl.texParameterf(this.gl.TEXTURE_2D, this.anisoExt.TEXTURE_MAX_ANISOTROPY_EXT, r2);
              }
            } }, { key: "loadExtraImages", value: function(t3) {
              var e3 = this;
              Object.keys(t3).forEach(function(i3) {
                var s3 = t3[i3], r2 = s3.data, a2 = s3.width, h2 = s3.height;
                if (!e3.samplers[i3]) {
                  var o2 = new Image();
                  o2.onload = function() {
                    e3.samplers[i3] = e3.gl.createTexture(), e3.bindTexture(e3.samplers[i3], o2, a2, h2);
                  }, o2.src = r2;
                }
              });
            } }, { key: "getTexture", value: function(t3) {
              var e3 = this.samplers[t3];
              return e3 || this.samplers.clouds2;
            } }]) && K(e2.prototype, i2), s2 && K(e2, s2), t2;
          })();
          function Z(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var $ = (function() {
            function t2(e3) {
              var i3 = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {};
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.texsizeX = i3.texsizeX, this.texsizeY = i3.texsizeY, this.aspectx = i3.aspectx, this.aspecty = i3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.buildPositions(), this.textTexture = this.gl.createTexture(), this.indexBuf = e3.createBuffer(), this.positionVertexBuf = this.gl.createBuffer(), this.vertexBuf = this.gl.createBuffer(), this.canvas = document.createElement("canvas"), this.canvas.width = this.texsizeX, this.canvas.height = this.texsizeY, this.context2D = this.canvas.getContext("2d"), this.floatPrecision = _.getFragmentFloatPrecision(this.gl), this.createShader();
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "generateTitleTexture", value: function(t3) {
              this.context2D.clearRect(0, 0, this.texsizeX, this.texsizeY), this.fontSize = Math.floor(this.texsizeX / 256 * 16), this.fontSize = Math.max(this.fontSize, 6), this.context2D.font = "italic ".concat(this.fontSize, "px Times New Roman");
              var e3 = t3, i3 = this.context2D.measureText(e3).width;
              if (i3 > this.texsizeX) {
                var s3 = this.texsizeX / i3 * 0.91;
                e3 = "".concat(e3.substring(0, Math.floor(e3.length * s3)), "..."), i3 = this.context2D.measureText(e3).width;
              }
              this.context2D.fillStyle = "#FFFFFF", this.context2D.fillText(e3, (this.texsizeX - i3) / 2, this.texsizeY / 2);
              var r2 = new Uint8Array(this.context2D.getImageData(0, 0, this.texsizeX, this.texsizeY).data.buffer);
              this.gl.pixelStorei(this.gl.UNPACK_FLIP_Y_WEBGL, true), this.gl.bindTexture(this.gl.TEXTURE_2D, this.textTexture), this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, this.texsizeX, this.texsizeY, 0, this.gl.RGBA, this.gl.UNSIGNED_BYTE, r2), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR_MIPMAP_LINEAR), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.gl.bindTexture(this.gl.TEXTURE_2D, null);
            } }, { key: "updateGlobals", value: function(t3) {
              this.texsizeX = t3.texsizeX, this.texsizeY = t3.texsizeY, this.aspectx = t3.aspectx, this.aspecty = t3.aspecty, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.canvas.width = this.texsizeX, this.canvas.height = this.texsizeY;
            } }, { key: "buildPositions", value: function() {
              for (var t3 = [], e3 = 0; e3 < 8; e3++) for (var i3 = e3 * (2 / 7) - 1, s3 = 0; s3 < 16; s3++) {
                var r2 = s3 * (2 / 15) - 1;
                t3.push(r2, -i3, 0);
              }
              for (var a2 = [], h2 = 0; h2 < 7; h2++) for (var o2 = 0; o2 < 15; o2++) {
                var n2 = o2 + 16 * h2, l2 = o2 + 16 * (h2 + 1), m2 = o2 + 1 + 16 * (h2 + 1), u2 = o2 + 1 + 16 * h2;
                a2.push(n2, l2, u2), a2.push(l2, m2, u2);
              }
              this.vertices = new Float32Array(t3), this.indices = new Uint16Array(a2);
            } }, { key: "createShader", value: function() {
              this.shaderProgram = this.gl.createProgram();
              var t3 = this.gl.createShader(this.gl.VERTEX_SHADER);
              this.gl.shaderSource(t3, "#version 300 es\n       const vec2 halfmad = vec2(0.5);\n       in vec2 aPos;\n       in vec2 aUv;\n       out vec2 uv_orig;\n       out vec2 uv;\n       void main(void) {\n         gl_Position = vec4(aPos, 0.0, 1.0);\n         uv_orig = aPos * halfmad + halfmad;\n         uv = aUv;\n       }"), this.gl.compileShader(t3);
              var e3 = this.gl.createShader(this.gl.FRAGMENT_SHADER);
              this.gl.shaderSource(e3, "#version 300 es\n       precision ".concat(this.floatPrecision, " float;\n       precision highp int;\n       precision mediump sampler2D;\n\n       in vec2 uv_orig;\n       in vec2 uv;\n       out vec4 fragColor;\n       uniform sampler2D uTexture;\n       uniform float textColor;\n\n       void main(void) {\n         fragColor = texture(uTexture, uv) * vec4(textColor);\n       }")), this.gl.compileShader(e3), this.gl.attachShader(this.shaderProgram, t3), this.gl.attachShader(this.shaderProgram, e3), this.gl.linkProgram(this.shaderProgram), this.positionLocation = this.gl.getAttribLocation(this.shaderProgram, "aPos"), this.uvLocation = this.gl.getAttribLocation(this.shaderProgram, "aUv"), this.textureLoc = this.gl.getUniformLocation(this.shaderProgram, "uTexture"), this.textColorLoc = this.gl.getUniformLocation(this.shaderProgram, "textColor");
            } }, { key: "generateUvs", value: function(t3, e3, i3) {
              for (var s3 = [], r2 = 0; r2 < 8; r2++) for (var a2 = 0; a2 < 16; a2++) {
                var h2 = 2 * (a2 / 15) - 1, o2 = 2 * (0.75 * (r2 / 7 - 0.5) + 0.5) - 1;
                t3 >= 1 && (o2 += 1 / this.texsizeY), s3.push(h2, e3 ? o2 : -o2);
              }
              for (var n2 = Math.max(0, 1 - 1.5 * t3), l2 = 1.3 * Math.pow(n2, 1.8), m2 = 0; m2 < 8; m2++) for (var u2 = 0; u2 < 16; u2++) {
                var g2 = 16 * m2 + u2;
                s3[g2] += 0.07 * l2 * Math.sin(0.31 * i3.time + 0.39 * s3[g2] - 1.94 * s3[g2 + 1]), s3[g2] += 0.044 * l2 * Math.sin(0.81 * i3.time - 1.91 * s3[g2] + 0.27 * s3[g2 + 1]), s3[g2] += 0.061 * l2 * Math.sin(1.31 * i3.time + 0.61 * s3[g2] + 0.74 * s3[g2 + 1]), s3[g2 + 1] += 0.061 * l2 * Math.sin(0.37 * i3.time + 1.83 * s3[g2] + 0.69 * s3[g2 + 1]), s3[g2 + 1] += 0.07 * l2 * Math.sin(0.67 * i3.time + 0.42 * s3[g2] - 1.39 * s3[g2 + 1]), s3[g2 + 1] += 0.087 * l2 * Math.sin(1.07 * i3.time + 3.55 * s3[g2] + 0.89 * s3[g2 + 1]);
              }
              for (var c2 = 1.01 / (Math.pow(t3, 0.21) + 0.01), A2 = 0; A2 < s3.length / 2; A2++) s3[2 * A2] *= c2, s3[2 * A2 + 1] *= c2 * this.invAspecty, s3[2 * A2] = (s3[2 * A2] + 1) / 2, s3[2 * A2 + 1] = (s3[2 * A2 + 1] + 1) / 2;
              return new Float32Array(s3);
            } }, { key: "renderTitle", value: function(t3, e3, i3) {
              this.gl.useProgram(this.shaderProgram);
              var s3 = this.generateUvs(t3, e3, i3);
              this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.indexBuf), this.gl.bufferData(this.gl.ELEMENT_ARRAY_BUFFER, this.indices, this.gl.STATIC_DRAW), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionVertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, this.vertices, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.positionLocation, 3, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.positionLocation), this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexBuf), this.gl.bufferData(this.gl.ARRAY_BUFFER, s3, this.gl.STATIC_DRAW), this.gl.vertexAttribPointer(this.uvLocation, 2, this.gl.FLOAT, false, 0, 0), this.gl.enableVertexAttribArray(this.uvLocation), this.gl.activeTexture(this.gl.TEXTURE0), this.gl.bindTexture(this.gl.TEXTURE_2D, this.textTexture), this.gl.uniform1i(this.textureLoc, 0), this.gl.uniform1f(this.textColorLoc, Math.pow(t3, 0.3)), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA), this.gl.drawElements(this.gl.TRIANGLES, this.indices.length, this.gl.UNSIGNED_SHORT, 0);
            } }]) && Z(e2.prototype, i2), s2 && Z(e2, s2), t2;
          })();
          function tt(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var et = (function() {
            function t2(e3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.mesh_width = e3.mesh_width, this.mesh_height = e3.mesh_height, this.aspectx = e3.aspectx, this.aspecty = e3.aspecty, this.vertInfoA = new Float32Array((this.mesh_width + 1) * (this.mesh_height + 1)), this.vertInfoC = new Float32Array((this.mesh_width + 1) * (this.mesh_height + 1)), this.createBlendPattern();
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "resizeMatrixValues", value: function(t3, e3, i3, s3, r2) {
              for (var a2 = new Float32Array((s3 + 1) * (r2 + 1)), h2 = 0, o2 = 0; o2 < r2 + 1; o2++) for (var n2 = 0; n2 < s3 + 1; n2++) {
                var l2 = n2 / r2, m2 = o2 / s3;
                l2 *= e3 + 1, m2 *= i3 + 1, l2 = Math.clamp(l2, 0, e3 - 1), m2 = Math.clamp(m2, 0, i3 - 1);
                var u2 = Math.floor(l2), g2 = Math.floor(m2), c2 = l2 - u2, A2 = m2 - g2, f2 = t3[g2 * (e3 + 1) + u2], d2 = t3[g2 * (e3 + 1) + (u2 + 1)], v2 = t3[(g2 + 1) * (e3 + 1) + u2], p2 = t3[(g2 + 1) * (e3 + 1) + (u2 + 1)];
                a2[h2] = f2 * (1 - c2) * (1 - A2) + d2 * c2 * (1 - A2) + v2 * (1 - c2) * A2 + p2 * c2 * A2, h2 += 1;
              }
              return a2;
            } }], (i2 = [{ key: "updateGlobals", value: function(e3) {
              var i3 = this.mesh_width, s3 = this.mesh_height;
              this.mesh_width = e3.mesh_width, this.mesh_height = e3.mesh_height, this.aspectx = e3.aspectx, this.aspecty = e3.aspecty, this.mesh_width === i3 && this.mesh_height === s3 || (this.vertInfoA = t2.resizeMatrixValues(this.vertInfoA, i3, s3, this.mesh_width, this.mesh_height), this.vertInfoC = t2.resizeMatrixValues(this.vertInfoC, i3, s3, this.mesh_width, this.mesh_height));
            } }, { key: "genPlasma", value: function(t3, e3, i3, s3, r2) {
              var a2 = Math.floor((t3 + e3) / 2), h2 = Math.floor((i3 + s3) / 2), o2 = this.vertInfoC[i3 * (this.mesh_width + 1) + t3], n2 = this.vertInfoC[i3 * (this.mesh_width + 1) + e3], l2 = this.vertInfoC[s3 * (this.mesh_width + 1) + t3], m2 = this.vertInfoC[s3 * (this.mesh_width + 1) + e3];
              s3 - i3 >= 2 && (0 === t3 && (this.vertInfoC[h2 * (this.mesh_width + 1) + t3] = 0.5 * (o2 + l2) + (2 * Math.random() - 1) * r2 * this.aspecty), this.vertInfoC[h2 * (this.mesh_width + 1) + e3] = 0.5 * (n2 + m2) + (2 * Math.random() - 1) * r2 * this.aspecty), e3 - t3 >= 2 && (0 === i3 && (this.vertInfoC[i3 * (this.mesh_width + 1) + a2] = 0.5 * (o2 + n2) + (2 * Math.random() - 1) * r2 * this.aspectx), this.vertInfoC[s3 * (this.mesh_width + 1) + a2] = 0.5 * (l2 + m2) + (2 * Math.random() - 1) * r2 * this.aspectx), s3 - i3 >= 2 && e3 - t3 >= 2 && (o2 = this.vertInfoC[h2 * (this.mesh_width + 1) + t3], n2 = this.vertInfoC[h2 * (this.mesh_width + 1) + e3], l2 = this.vertInfoC[i3 * (this.mesh_width + 1) + a2], m2 = this.vertInfoC[s3 * (this.mesh_width + 1) + a2], this.vertInfoC[h2 * (this.mesh_width + 1) + a2] = 0.25 * (l2 + m2 + o2 + n2) + (2 * Math.random() - 1) * r2, this.genPlasma(t3, a2, i3, h2, 0.5 * r2), this.genPlasma(a2, e3, i3, h2, 0.5 * r2), this.genPlasma(t3, a2, h2, s3, 0.5 * r2), this.genPlasma(a2, e3, h2, s3, 0.5 * r2));
            } }, { key: "createBlendPattern", value: function() {
              var t3 = 1 + Math.floor(3 * Math.random());
              if (0 === t3) for (var e3 = 0, i3 = 0; i3 <= this.mesh_height; i3++) for (var s3 = 0; s3 <= this.mesh_width; s3++) this.vertInfoA[e3] = 1, this.vertInfoC[e3] = 0, e3 += 1;
              else if (1 === t3) for (var r2 = 6.28 * Math.random(), a2 = Math.cos(r2), h2 = Math.sin(r2), o2 = 0.1 + 0.2 * Math.random(), n2 = 1 / o2, l2 = 0, m2 = 0; m2 <= this.mesh_height; m2++) for (var u2 = m2 / this.mesh_height * this.aspecty, g2 = 0; g2 <= this.mesh_width; g2++) {
                var c2 = (g2 / this.mesh_width * this.aspectx - 0.5) * a2 + (u2 - 0.5) * h2 + 0.5;
                c2 = (c2 - 0.5) / Math.sqrt(2) + 0.5, this.vertInfoA[l2] = n2 * (1 + o2), this.vertInfoC[l2] = n2 * c2 - n2, l2 += 1;
              }
              else if (2 === t3) {
                var A2 = 0.12 + 0.13 * Math.random(), f2 = 1 / A2;
                this.vertInfoC[0] = Math.random(), this.vertInfoC[this.mesh_width] = Math.random(), this.vertInfoC[this.mesh_height * (this.mesh_width + 1)] = Math.random(), this.vertInfoC[this.mesh_height * (this.mesh_width + 1) + this.mesh_width] = Math.random(), this.genPlasma(0, this.mesh_width, 0, this.mesh_height, 0.25);
                for (var d2 = this.vertInfoC[0], v2 = this.vertInfoC[0], p2 = 0, _2 = 0; _2 <= this.mesh_height; _2++) for (var x2 = 0; x2 <= this.mesh_width; x2++) d2 > this.vertInfoC[p2] && (d2 = this.vertInfoC[p2]), v2 < this.vertInfoC[p2] && (v2 = this.vertInfoC[p2]), p2 += 1;
                var b2 = 1 / (v2 - d2);
                p2 = 0;
                for (var T2 = 0; T2 <= this.mesh_height; T2++) for (var E2 = 0; E2 <= this.mesh_width; E2++) {
                  var P2 = (this.vertInfoC[p2] - d2) * b2;
                  this.vertInfoA[p2] = f2 * (1 + A2), this.vertInfoC[p2] = f2 * P2 - f2, p2 += 1;
                }
              } else if (3 === t3) for (var R2 = 0.02 + 0.14 * Math.random() + 0.34 * Math.random(), L2 = 1 / R2, S2 = 2 * Math.floor(2 * Math.random()) - 1, y2 = 0, w2 = 0; w2 <= this.mesh_height; w2++) for (var U2 = (w2 / this.mesh_height - 0.5) * this.aspecty, M2 = 0; M2 <= this.mesh_width; M2++) {
                var F2 = (M2 / this.mesh_width - 0.5) * this.aspectx, q2 = 1.41421 * Math.sqrt(F2 * F2 + U2 * U2);
                -1 === S2 && (q2 = 1 - q2), this.vertInfoA[y2] = L2 * (1 + R2), this.vertInfoC[y2] = L2 * q2 - L2, y2 += 1;
              }
            } }]) && tt(e2.prototype, i2), s2 && tt(e2, s2), t2;
          })();
          function it(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var st = (function() {
            function t2(e3, i3, s3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.gl = e3, this.audio = i3, this.frameNum = 0, this.fps = 30, this.time = 0, this.presetTime = 0, this.lastTime = performance.now(), this.timeHist = [0], this.timeHistMax = 120, this.blending = false, this.blendStartTime = 0, this.blendProgress = 0, this.blendDuration = 0, this.width = s3.width || 1200, this.height = s3.height || 900, this.mesh_width = s3.meshWidth || 48, this.mesh_height = s3.meshHeight || 36, this.pixelRatio = s3.pixelRatio || window.devicePixelRatio || 1, this.textureRatio = s3.textureRatio || 1, this.outputFXAA = s3.outputFXAA || false, this.texsizeX = this.width * this.pixelRatio * this.textureRatio, this.texsizeY = this.height * this.pixelRatio * this.textureRatio, this.aspectx = this.texsizeY > this.texsizeX ? this.texsizeX / this.texsizeY : 1, this.aspecty = this.texsizeX > this.texsizeY ? this.texsizeY / this.texsizeX : 1, this.invAspectx = 1 / this.aspectx, this.invAspecty = 1 / this.aspecty, this.qs = c.range(1, 33).map(function(t3) {
                return "q".concat(t3);
              }), this.ts = c.range(1, 9).map(function(t3) {
                return "t".concat(t3);
              }), this.regs = c.range(0, 100).map(function(t3) {
                return t3 < 10 ? "reg0".concat(t3) : "reg".concat(t3);
              }), this.blurRatios = [[0.5, 0.25], [0.125, 0.125], [0.0625, 0.0625]], this.audioLevels = new n(this.audio), this.prevFrameBuffer = this.gl.createFramebuffer(), this.targetFrameBuffer = this.gl.createFramebuffer(), this.prevTexture = this.gl.createTexture(), this.targetTexture = this.gl.createTexture(), this.compFrameBuffer = this.gl.createFramebuffer(), this.compTexture = this.gl.createTexture(), this.anisoExt = this.gl.getExtension("EXT_texture_filter_anisotropic") || this.gl.getExtension("MOZ_EXT_texture_filter_anisotropic") || this.gl.getExtension("WEBKIT_EXT_texture_filter_anisotropic"), this.bindFrameBufferTexture(this.prevFrameBuffer, this.prevTexture), this.bindFrameBufferTexture(this.targetFrameBuffer, this.targetTexture), this.bindFrameBufferTexture(this.compFrameBuffer, this.compTexture);
              var r2 = { pixelRatio: this.pixelRatio, textureRatio: this.textureRatio, texsizeX: this.texsizeX, texsizeY: this.texsizeY, mesh_width: this.mesh_width, mesh_height: this.mesh_height, aspectx: this.aspectx, aspecty: this.aspecty };
              this.noise = new j(e3), this.image = new J(e3), this.warpShader = new B(e3, this.noise, this.image, r2), this.compShader = new D(e3, this.noise, this.image, r2), this.outputShader = new I(e3, r2), this.prevWarpShader = new B(e3, this.noise, this.image, r2), this.prevCompShader = new D(e3, this.noise, this.image, r2), this.numBlurPasses = 0, this.blurShader1 = new G(0, this.blurRatios, e3, r2), this.blurShader2 = new G(1, this.blurRatios, e3, r2), this.blurShader3 = new G(2, this.blurRatios, e3, r2), this.blurTexture1 = this.blurShader1.blurVerticalTexture, this.blurTexture2 = this.blurShader2.blurVerticalTexture, this.blurTexture3 = this.blurShader3.blurVerticalTexture, this.basicWaveform = new E(e3, r2), this.customWaveforms = c.range(4).map(function(t3) {
                return new R(t3, e3, r2);
              }), this.customShapes = c.range(4).map(function(t3) {
                return new S(t3, e3, r2);
              }), this.prevCustomWaveforms = c.range(4).map(function(t3) {
                return new R(t3, e3, r2);
              }), this.prevCustomShapes = c.range(4).map(function(t3) {
                return new S(t3, e3, r2);
              }), this.darkenCenter = new M(e3, r2), this.innerBorder = new w(e3, r2), this.outerBorder = new w(e3, r2), this.motionVectors = new q(e3, r2), this.titleText = new $(e3, r2), this.blendPattern = new et(r2), this.resampleShader = new k(e3), this.supertext = { startTime: -1 }, this.warpUVs = new Float32Array((this.mesh_width + 1) * (this.mesh_height + 1) * 2), this.warpColor = new Float32Array((this.mesh_width + 1) * (this.mesh_height + 1) * 4), this.gl.clearColor(0, 0, 0, 1), this.blankPreset = m.a;
              var a2 = { frame: 0, time: 0, fps: 45, bass: 1, bass_att: 1, mid: 1, mid_att: 1, treb: 1, treb_att: 1 };
              this.preset = m.a, this.prevPreset = this.preset, this.presetEquationRunner = new f(this.preset, a2, r2), this.prevPresetEquationRunner = new f(this.prevPreset, a2, r2), this.regVars = this.presetEquationRunner.mdVSRegs;
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "getHighestBlur", value: function(t3) {
              return /sampler_blur3/.test(t3) ? 3 : /sampler_blur2/.test(t3) ? 2 : /sampler_blur1/.test(t3) ? 1 : 0;
            } }, { key: "mixFrameEquations", value: function(t3, e3, i3) {
              var s3 = 0.5 - 0.5 * Math.cos(t3 * Math.PI), r2 = 1 - s3, a2 = c.cloneVars(e3);
              return a2.decay = s3 * e3.decay + r2 * i3.decay, a2.wave_a = s3 * e3.wave_a + r2 * i3.wave_a, a2.wave_r = s3 * e3.wave_r + r2 * i3.wave_r, a2.wave_g = s3 * e3.wave_g + r2 * i3.wave_g, a2.wave_b = s3 * e3.wave_b + r2 * i3.wave_b, a2.wave_x = s3 * e3.wave_x + r2 * i3.wave_x, a2.wave_y = s3 * e3.wave_y + r2 * i3.wave_y, a2.wave_mystery = s3 * e3.wave_mystery + r2 * i3.wave_mystery, a2.ob_size = s3 * e3.ob_size + r2 * i3.ob_size, a2.ob_r = s3 * e3.ob_r + r2 * i3.ob_r, a2.ob_g = s3 * e3.ob_g + r2 * i3.ob_g, a2.ob_b = s3 * e3.ob_b + r2 * i3.ob_b, a2.ob_a = s3 * e3.ob_a + r2 * i3.ob_a, a2.ib_size = s3 * e3.ib_size + r2 * i3.ib_size, a2.ib_r = s3 * e3.ib_r + r2 * i3.ib_r, a2.ib_g = s3 * e3.ib_g + r2 * i3.ib_g, a2.ib_b = s3 * e3.ib_b + r2 * i3.ib_b, a2.ib_a = s3 * e3.ib_a + r2 * i3.ib_a, a2.mv_x = s3 * e3.mv_x + r2 * i3.mv_x, a2.mv_y = s3 * e3.mv_y + r2 * i3.mv_y, a2.mv_dx = s3 * e3.mv_dx + r2 * i3.mv_dx, a2.mv_dy = s3 * e3.mv_dy + r2 * i3.mv_dy, a2.mv_l = s3 * e3.mv_l + r2 * i3.mv_l, a2.mv_r = s3 * e3.mv_r + r2 * i3.mv_r, a2.mv_g = s3 * e3.mv_g + r2 * i3.mv_g, a2.mv_b = s3 * e3.mv_b + r2 * i3.mv_b, a2.mv_a = s3 * e3.mv_a + r2 * i3.mv_a, a2.echo_zoom = s3 * e3.echo_zoom + r2 * i3.echo_zoom, a2.echo_alpha = s3 * e3.echo_alpha + r2 * i3.echo_alpha, a2.echo_orient = s3 * e3.echo_orient + r2 * i3.echo_orient, a2.wave_dots = s3 < 0.5 ? i3.wave_dots : e3.wave_dots, a2.wave_thick = s3 < 0.5 ? i3.wave_thick : e3.wave_thick, a2.additivewave = s3 < 0.5 ? i3.additivewave : e3.additivewave, a2.wave_brighten = s3 < 0.5 ? i3.wave_brighten : e3.wave_brighten, a2.darken_center = s3 < 0.5 ? i3.darken_center : e3.darken_center, a2.gammaadj = s3 < 0.5 ? i3.gammaadj : e3.gammaadj, a2.wrap = s3 < 0.5 ? i3.wrap : e3.wrap, a2.invert = s3 < 0.5 ? i3.invert : e3.invert, a2.brighten = s3 < 0.5 ? i3.brighten : e3.brighten, a2.darken = s3 < 0.5 ? i3.darken : e3.darken, a2.solarize = s3 < 0.5 ? i3.brighten : e3.solarize, a2.b1n = s3 * e3.b1n + r2 * i3.b1n, a2.b2n = s3 * e3.b2n + r2 * i3.b2n, a2.b3n = s3 * e3.b3n + r2 * i3.b3n, a2.b1x = s3 * e3.b1x + r2 * i3.b1x, a2.b2x = s3 * e3.b2x + r2 * i3.b2x, a2.b3x = s3 * e3.b3x + r2 * i3.b3x, a2.b1ed = s3 * e3.b1ed + r2 * i3.b1ed, a2;
            } }, { key: "getBlurValues", value: function(t3) {
              var e3 = t3.b1n, i3 = t3.b2n, s3 = t3.b3n, r2 = t3.b1x, a2 = t3.b2x, h2 = t3.b3x;
              if (r2 - e3 < 0.1) {
                var o2 = 0.5 * (e3 + r2);
                e3 = o2 - 0.05, r2 = o2 - 0.05;
              }
              if ((a2 = Math.min(r2, a2)) - (i3 = Math.max(e3, i3)) < 0.1) {
                var n2 = 0.5 * (i3 + a2);
                i3 = n2 - 0.05, a2 = n2 - 0.05;
              }
              if ((h2 = Math.min(a2, h2)) - (s3 = Math.max(i3, s3)) < 0.1) {
                var l2 = 0.5 * (s3 + h2);
                s3 = l2 - 0.05, h2 = l2 - 0.05;
              }
              return { blurMins: [e3, i3, s3], blurMaxs: [r2, a2, h2] };
            } }], (i2 = [{ key: "loadPreset", value: function(e3, i3) {
              this.blendPattern.createBlendPattern(), this.blending = true, this.blendStartTime = this.time, this.blendDuration = i3, this.blendProgress = 0, this.prevPresetEquationRunner = this.presetEquationRunner, this.prevPreset = this.preset, this.preset = e3, this.preset.baseVals.old_wave_mode = this.prevPreset.baseVals.wave_mode, this.presetTime = this.time;
              var s3 = { frame: this.frameNum, time: this.time, fps: this.fps, bass: this.audioLevels.bass, bass_att: this.audioLevels.bass_att, mid: this.audioLevels.mid, mid_att: this.audioLevels.mid_att, treb: this.audioLevels.treb, treb_att: this.audioLevels.treb_att }, r2 = { pixelRatio: this.pixelRatio, textureRatio: this.textureRatio, texsizeX: this.texsizeX, texsizeY: this.texsizeY, mesh_width: this.mesh_width, mesh_height: this.mesh_height, aspectx: this.aspectx, aspecty: this.aspecty };
              this.presetEquationRunner = new f(this.preset, s3, r2), this.regVars = this.presetEquationRunner.mdVSRegs;
              var a2 = this.prevWarpShader;
              this.prevWarpShader = this.warpShader, this.warpShader = a2;
              var h2 = this.prevCompShader;
              this.prevCompShader = this.compShader, this.compShader = h2;
              var o2 = this.preset.warp.trim(), n2 = this.preset.comp.trim();
              this.warpShader.updateShader(o2), this.compShader.updateShader(n2), 0 === o2.length ? this.numBlurPasses = 0 : this.numBlurPasses = t2.getHighestBlur(o2), 0 !== n2.length && (this.numBlurPasses = Math.max(this.numBlurPasses, t2.getHighestBlur(n2)));
            } }, { key: "loadExtraImages", value: function(t3) {
              this.image.loadExtraImages(t3);
            } }, { key: "setRendererSize", value: function(t3, e3, i3) {
              var s3 = this.texsizeX, r2 = this.texsizeY;
              if (this.width = t3, this.height = e3, this.mesh_width = i3.meshWidth || this.mesh_width, this.mesh_height = i3.meshHeight || this.mesh_height, this.pixelRatio = i3.pixelRatio || this.pixelRatio, this.textureRatio = i3.textureRatio || this.textureRatio, this.texsizeX = t3 * this.pixelRatio * this.textureRatio, this.texsizeY = e3 * this.pixelRatio * this.textureRatio, this.aspectx = this.texsizeY > this.texsizeX ? this.texsizeX / this.texsizeY : 1, this.aspecty = this.texsizeX > this.texsizeY ? this.texsizeY / this.texsizeX : 1, this.texsizeX !== s3 || this.texsizeY !== r2) {
                var a2 = this.gl.createTexture();
                this.bindFrameBufferTexture(this.targetFrameBuffer, a2), this.bindFrambufferAndSetViewport(this.targetFrameBuffer, this.texsizeX, this.texsizeY), this.resampleShader.renderQuadTexture(this.targetTexture), this.targetTexture = a2, this.bindFrameBufferTexture(this.prevFrameBuffer, this.prevTexture), this.bindFrameBufferTexture(this.compFrameBuffer, this.compTexture);
              }
              this.updateGlobals(), this.frameNum > 0 && this.renderToScreen();
            } }, { key: "setInternalMeshSize", value: function(t3, e3) {
              this.mesh_width = t3, this.mesh_height = e3, this.updateGlobals();
            } }, { key: "setOutputAA", value: function(t3) {
              this.outputFXAA = t3;
            } }, { key: "updateGlobals", value: function() {
              var t3 = { pixelRatio: this.pixelRatio, textureRatio: this.textureRatio, texsizeX: this.texsizeX, texsizeY: this.texsizeY, mesh_width: this.mesh_width, mesh_height: this.mesh_height, aspectx: this.aspectx, aspecty: this.aspecty };
              this.presetEquationRunner.updateGlobals(t3), this.prevPresetEquationRunner.updateGlobals(t3), this.warpShader.updateGlobals(t3), this.prevWarpShader.updateGlobals(t3), this.compShader.updateGlobals(t3), this.prevCompShader.updateGlobals(t3), this.outputShader.updateGlobals(t3), this.blurShader1.updateGlobals(t3), this.blurShader2.updateGlobals(t3), this.blurShader3.updateGlobals(t3), this.basicWaveform.updateGlobals(t3), this.customWaveforms.forEach(function(e3) {
                return e3.updateGlobals(t3);
              }), this.customShapes.forEach(function(e3) {
                return e3.updateGlobals(t3);
              }), this.prevCustomWaveforms.forEach(function(e3) {
                return e3.updateGlobals(t3);
              }), this.prevCustomShapes.forEach(function(e3) {
                return e3.updateGlobals(t3);
              }), this.darkenCenter.updateGlobals(t3), this.innerBorder.updateGlobals(t3), this.outerBorder.updateGlobals(t3), this.motionVectors.updateGlobals(t3), this.titleText.updateGlobals(t3), this.blendPattern.updateGlobals(t3), this.warpUVs = new Float32Array((this.mesh_width + 1) * (this.mesh_height + 1) * 2), this.warpColor = new Float32Array((this.mesh_width + 1) * (this.mesh_height + 1) * 4);
            } }, { key: "calcTimeAndFPS", value: function(t3) {
              var e3;
              if (t3) e3 = t3;
              else {
                var i3 = performance.now();
                ((e3 = (i3 - this.lastTime) / 1e3) > 1 || e3 < 0 || this.frame < 2) && (e3 = 1 / 30), this.lastTime = i3;
              }
              this.time += 1 / this.fps, this.blending && (this.blendProgress = (this.time - this.blendStartTime) / this.blendDuration, this.blendProgress > 1 && (this.blending = false));
              var s3 = this.timeHist[this.timeHist.length - 1] + e3;
              this.timeHist.push(s3), this.timeHist.length > this.timeHistMax && this.timeHist.shift();
              var r2 = this.timeHist.length / (s3 - this.timeHist[0]);
              if (Math.abs(r2 - this.fps) > 3 && this.frame > this.timeHistMax) this.fps = r2;
              else {
                this.fps = 0.93 * this.fps + (1 - 0.93) * r2;
              }
            } }, { key: "runPixelEquations", value: function(t3, e3, i3, s3) {
              for (var r2 = this.mesh_width, a2 = this.mesh_height, h2 = r2 + 1, o2 = a2 + 1, n2 = this.time * e3.warpanimspeed, l2 = 1 / e3.warpscale, m2 = 11.68 + 4 * Math.cos(1.413 * n2 + 10), u2 = 8.77 + 3 * Math.cos(1.113 * n2 + 7), g2 = 10.54 + 3 * Math.cos(1.233 * n2 + 3), A2 = 11.49 + 4 * Math.cos(0.933 * n2 + 5), f2 = 0 / this.texsizeX, d2 = 0 / this.texsizeY, v2 = this.aspectx, p2 = this.aspecty, _2 = c.cloneVars(e3), x2 = 0, b2 = 0, T2 = 0; T2 < o2; T2++) for (var E2 = 0; E2 < h2; E2++) {
                var P2 = E2 / r2 * 2 - 1, R2 = T2 / a2 * 2 - 1, L2 = Math.sqrt(P2 * P2 * v2 * v2 + R2 * R2 * p2 * p2);
                if (i3) {
                  var S2 = void 0;
                  S2 = T2 === a2 / 2 && E2 === r2 / 2 ? 0 : c.atan2(R2 * p2, P2 * v2), _2.x = 0.5 * P2 * v2 + 0.5, _2.y = -0.5 * R2 * p2 + 0.5, _2.rad = L2, _2.ang = S2, _2.zoom = e3.zoom, _2.zoomexp = e3.zoomexp, _2.rot = e3.rot, _2.warp = e3.warp, _2.cx = e3.cx, _2.cy = e3.cy, _2.dx = e3.dx, _2.dy = e3.dy, _2.sx = e3.sx, _2.sy = e3.sy, _2 = t3.pixel_eqs(_2);
                }
                var y2 = _2.warp, w2 = _2.zoom, U2 = _2.zoomexp, M2 = _2.cx, F2 = _2.cy, q2 = _2.sx, z2 = _2.sy, B2 = _2.dx, C2 = _2.dy, D2 = _2.rot, V2 = 1 / Math.pow(w2, Math.pow(U2, 2 * L2 - 1)), I2 = 0.5 * P2 * v2 * V2 + 0.5, X2 = 0.5 * -R2 * p2 * V2 + 0.5;
                I2 = (I2 - M2) / q2 + M2, X2 = (X2 - F2) / z2 + F2, 0 !== y2 && (I2 += 35e-4 * y2 * Math.sin(0.333 * n2 + l2 * (P2 * m2 - R2 * A2)), X2 += 35e-4 * y2 * Math.cos(0.375 * n2 - l2 * (P2 * g2 + R2 * u2)), I2 += 35e-4 * y2 * Math.cos(0.753 * n2 - l2 * (P2 * u2 - R2 * g2)), X2 += 35e-4 * y2 * Math.sin(0.825 * n2 + l2 * (P2 * m2 + R2 * A2)));
                var k2 = I2 - M2, N2 = X2 - F2, O2 = Math.cos(D2), W2 = Math.sin(D2);
                if (I2 = k2 * O2 - N2 * W2 + M2, X2 = k2 * W2 + N2 * O2 + F2, I2 = ((I2 -= B2) - 0.5) / v2 + 0.5, X2 = ((X2 -= C2) - 0.5) / p2 + 0.5, I2 += f2, X2 += d2, s3) {
                  var Q2 = this.blendPattern.vertInfoA[x2 / 2] * this.blendProgress + this.blendPattern.vertInfoC[x2 / 2];
                  Q2 = Math.clamp(Q2, 0, 1), this.warpUVs[x2] = this.warpUVs[x2] * Q2 + I2 * (1 - Q2), this.warpUVs[x2 + 1] = this.warpUVs[x2 + 1] * Q2 + X2 * (1 - Q2), this.warpColor[b2 + 0] = 1, this.warpColor[b2 + 1] = 1, this.warpColor[b2 + 2] = 1, this.warpColor[b2 + 3] = Q2;
                } else this.warpUVs[x2] = I2, this.warpUVs[x2 + 1] = X2, this.warpColor[b2 + 0] = 1, this.warpColor[b2 + 1] = 1, this.warpColor[b2 + 2] = 1, this.warpColor[b2 + 3] = 1;
                x2 += 2, b2 += 4;
              }
              this.mdVSVertex = _2;
            } }, { key: "bindFrambufferAndSetViewport", value: function(t3, e3, i3) {
              this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, t3), this.gl.viewport(0, 0, e3, i3);
            } }, { key: "bindFrameBufferTexture", value: function(t3, e3) {
              if (this.gl.bindTexture(this.gl.TEXTURE_2D, e3), this.gl.pixelStorei(this.gl.UNPACK_ALIGNMENT, 1), this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, this.texsizeX, this.texsizeY, 0, this.gl.RGBA, this.gl.UNSIGNED_BYTE, new Uint8Array(this.texsizeX * this.texsizeY * 4)), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR_MIPMAP_LINEAR), this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR), this.anisoExt) {
                var i3 = this.gl.getParameter(this.anisoExt.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
                this.gl.texParameterf(this.gl.TEXTURE_2D, this.anisoExt.TEXTURE_MAX_ANISOTROPY_EXT, i3);
              }
              this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, t3), this.gl.framebufferTexture2D(this.gl.FRAMEBUFFER, this.gl.COLOR_ATTACHMENT0, this.gl.TEXTURE_2D, e3, 0);
            } }, { key: "render", value: function() {
              var e3 = this, i3 = arguments.length > 0 && void 0 !== arguments[0] ? arguments[0] : {}, s3 = i3.audioLevels, r2 = i3.elapsedTime;
              this.calcTimeAndFPS(r2), this.frameNum += 1, s3 ? this.audio.updateAudio(s3.timeByteArray, s3.timeByteArrayL, s3.timeByteArrayR) : this.audio.sampleAudio(), this.audioLevels.updateAudioLevels(this.fps, this.frameNum);
              var a2 = { frame: this.frameNum, time: this.time, fps: this.fps, bass: this.audioLevels.bass, bass_att: this.audioLevels.bass_att, mid: this.audioLevels.mid, mid_att: this.audioLevels.mid_att, treb: this.audioLevels.treb, treb_att: this.audioLevels.treb_att, meshx: this.mesh_width, meshy: this.mesh_height, aspectx: this.invAspectx, aspecty: this.invAspecty, pixelsx: this.texsizeX, pixelsy: this.texsizeY }, h2 = Object.assign({}, a2);
              h2.gmegabuf = this.prevPresetEquationRunner.gmegabuf, a2.gmegabuf = this.presetEquationRunner.gmegabuf, Object.assign(a2, this.regVars), this.presetEquationRunner.runFrameEquations(a2);
              var o2, n2 = this.presetEquationRunner.mdVSFrame;
              this.runPixelEquations(this.presetEquationRunner.preset, n2, this.presetEquationRunner.runVertEQs, false), Object.assign(this.regVars, c.pick(this.mdVSVertex, this.regs)), Object.assign(a2, this.regVars), this.blending ? (this.prevPresetEquationRunner.runFrameEquations(h2), this.runPixelEquations(this.prevPresetEquationRunner.preset, this.prevPresetEquationRunner.mdVSFrame, this.prevPresetEquationRunner.runVertEQs, true), o2 = t2.mixFrameEquations(this.blendProgress, n2, this.prevPresetEquationRunner.mdVSFrame)) : o2 = n2;
              var l2 = this.targetTexture;
              this.targetTexture = this.prevTexture, this.prevTexture = l2;
              var m2 = this.targetFrameBuffer;
              this.targetFrameBuffer = this.prevFrameBuffer, this.prevFrameBuffer = m2, this.gl.bindTexture(this.gl.TEXTURE_2D, this.prevTexture), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.bindFrambufferAndSetViewport(this.targetFrameBuffer, this.texsizeX, this.texsizeY), this.gl.clear(this.gl.COLOR_BUFFER_BIT), this.gl.enable(this.gl.BLEND), this.gl.blendEquation(this.gl.FUNC_ADD), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
              var u2 = t2.getBlurValues(o2), g2 = u2.blurMins, A2 = u2.blurMaxs;
              this.blending ? (this.prevWarpShader.renderQuadTexture(false, this.prevTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, g2, A2, this.prevPresetEquationRunner.mdVSFrame, this.warpUVs, this.warpColor), this.warpShader.renderQuadTexture(true, this.prevTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, g2, A2, o2, this.warpUVs, this.warpColor)) : this.warpShader.renderQuadTexture(false, this.prevTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, g2, A2, n2, this.warpUVs, this.warpColor), this.numBlurPasses > 0 && (this.blurShader1.renderBlurTexture(this.targetTexture, n2, g2, A2), this.numBlurPasses > 1 && (this.blurShader2.renderBlurTexture(this.blurTexture1, n2, g2, A2), this.numBlurPasses > 2 && this.blurShader3.renderBlurTexture(this.blurTexture2, n2, g2, A2)), this.bindFrambufferAndSetViewport(this.targetFrameBuffer, this.texsizeX, this.texsizeY)), this.motionVectors.drawMotionVectors(o2, this.warpUVs), this.preset.shapes && this.preset.shapes.length > 0 && this.customShapes.forEach(function(t3, i4) {
                t3.drawCustomShape(e3.blending ? e3.blendProgress : 1, a2, e3.presetEquationRunner, e3.preset.shapes[i4], e3.prevTexture);
              }), this.preset.waves && this.preset.waves.length > 0 && this.customWaveforms.forEach(function(t3, i4) {
                t3.drawCustomWaveform(e3.blending ? e3.blendProgress : 1, e3.audio.timeArrayL, e3.audio.timeArrayR, e3.audio.freqArrayL, e3.audio.freqArrayR, a2, e3.presetEquationRunner, e3.preset.waves[i4]);
              }), this.blending && (this.prevPreset.shapes && this.prevPreset.shapes.length > 0 && this.prevCustomShapes.forEach(function(t3, i4) {
                t3.drawCustomShape(1 - e3.blendProgress, h2, e3.prevPresetEquationRunner, e3.prevPreset.shapes[i4], e3.prevTexture);
              }), this.prevPreset.waves && this.prevPreset.waves.length > 0 && this.prevCustomWaveforms.forEach(function(t3, i4) {
                t3.drawCustomWaveform(1 - e3.blendProgress, e3.audio.timeArrayL, e3.audio.timeArrayR, e3.audio.freqArrayL, e3.audio.freqArrayR, h2, e3.prevPresetEquationRunner, e3.prevPreset.waves[i4]);
              })), this.basicWaveform.drawBasicWaveform(this.blending, this.blendProgress, this.audio.timeArrayL, this.audio.timeArrayR, o2), this.darkenCenter.drawDarkenCenter(o2);
              var f2 = [o2.ob_r, o2.ob_g, o2.ob_b, o2.ob_a];
              this.outerBorder.drawBorder(f2, o2.ob_size, 0);
              var d2 = [o2.ib_r, o2.ib_g, o2.ib_b, o2.ib_a];
              if (this.innerBorder.drawBorder(d2, o2.ib_size, o2.ob_size), this.supertext.startTime >= 0) {
                var v2 = (this.time - this.supertext.startTime) / this.supertext.duration;
                v2 >= 1 && this.titleText.renderTitle(v2, true, a2);
              }
              this.globalVars = a2, this.mdVSFrame = n2, this.mdVSFrameMixed = o2, this.renderToScreen();
            } }, { key: "renderToScreen", value: function() {
              this.outputFXAA ? this.bindFrambufferAndSetViewport(this.compFrameBuffer, this.texsizeX, this.texsizeY) : this.bindFrambufferAndSetViewport(null, this.width, this.height), this.gl.clear(this.gl.COLOR_BUFFER_BIT), this.gl.enable(this.gl.BLEND), this.gl.blendEquation(this.gl.FUNC_ADD), this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
              var e3 = t2.getBlurValues(this.mdVSFrameMixed), i3 = e3.blurMins, s3 = e3.blurMaxs;
              if (this.blending ? (this.prevCompShader.renderQuadTexture(false, this.targetTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, i3, s3, this.prevPresetEquationRunner.mdVSFrame, this.warpColor), this.compShader.renderQuadTexture(true, this.targetTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, i3, s3, this.mdVSFrameMixed, this.warpColor)) : this.compShader.renderQuadTexture(false, this.targetTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, i3, s3, this.mdVSFrame, this.warpColor), this.supertext.startTime >= 0) {
                var r2 = (this.time - this.supertext.startTime) / this.supertext.duration;
                this.titleText.renderTitle(r2, false, this.globalVars), r2 >= 1 && (this.supertext.startTime = -1);
              }
              this.outputFXAA && (this.gl.bindTexture(this.gl.TEXTURE_2D, this.compTexture), this.gl.generateMipmap(this.gl.TEXTURE_2D), this.bindFrambufferAndSetViewport(null, this.width, this.height), this.outputShader.renderQuadTexture(this.compTexture));
            } }, { key: "launchSongTitleAnim", value: function(t3) {
              this.supertext = { startTime: this.time, duration: 1.7 }, this.titleText.generateTitleTexture(t3);
            } }, { key: "toDataURL", value: function() {
              var e3 = this, i3 = new Uint8Array(this.texsizeX * this.texsizeY * 4), s3 = this.gl.createFramebuffer(), r2 = this.gl.createTexture();
              this.bindFrameBufferTexture(s3, r2);
              var a2 = t2.getBlurValues(this.mdVSFrameMixed), h2 = a2.blurMins, o2 = a2.blurMaxs;
              this.compShader.renderQuadTexture(false, this.targetTexture, this.blurTexture1, this.blurTexture2, this.blurTexture3, h2, o2, this.mdVSFrame, this.warpColor), this.gl.readPixels(0, 0, this.texsizeX, this.texsizeY, this.gl.RGBA, this.gl.UNSIGNED_BYTE, i3), Array.from({ length: this.texsizeY }, function(t3, s4) {
                return i3.slice(s4 * e3.texsizeX * 4, (s4 + 1) * e3.texsizeX * 4);
              }).forEach(function(t3, s4) {
                return i3.set(t3, (e3.texsizeY - s4 - 1) * e3.texsizeX * 4);
              });
              var n2 = document.createElement("canvas");
              n2.width = this.texsizeX, n2.height = this.texsizeY;
              var l2 = n2.getContext("2d"), m2 = l2.createImageData(this.texsizeX, this.texsizeY);
              return m2.data.set(i3), l2.putImageData(m2, 0, 0), this.gl.deleteTexture(r2), this.gl.deleteFramebuffer(s3), n2.toDataURL();
            } }, { key: "warpBufferToDataURL", value: function() {
              var t3 = new Uint8Array(this.texsizeX * this.texsizeY * 4);
              this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, this.targetFrameBuffer), this.gl.readPixels(0, 0, this.texsizeX, this.texsizeY, this.gl.RGBA, this.gl.UNSIGNED_BYTE, t3);
              var e3 = document.createElement("canvas");
              e3.width = this.texsizeX, e3.height = this.texsizeY;
              var i3 = e3.getContext("2d"), s3 = i3.createImageData(this.texsizeX, this.texsizeY);
              return s3.data.set(t3), i3.putImageData(s3, 0, 0), e3.toDataURL();
            } }]) && it(e2.prototype, i2), s2 && it(e2, s2), t2;
          })();
          function rt(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          var at = (function() {
            function t2(e3, i3, s3) {
              !(function(t3, e4) {
                if (!(t3 instanceof e4)) throw new TypeError("Cannot call a class as a function");
              })(this, t2), this.audio = new h(e3);
              var r2 = i3.getContext("webgl2", { alpha: false, antialias: false, depth: false, stencil: false, premultipliedAlpha: false });
              this.baseValsDefaults = { decay: 0.98, gammaadj: 2, echo_zoom: 2, echo_alpha: 0, echo_orient: 0, red_blue: 0, brighten: 0, darken: 0, wrap: 1, darken_center: 0, solarize: 0, invert: 0, fshader: 0, b1n: 0, b2n: 0, b3n: 0, b1x: 1, b2x: 1, b3x: 1, b1ed: 0.25, wave_mode: 0, additivewave: 0, wave_dots: 0, wave_thick: 0, wave_a: 0.8, wave_scale: 1, wave_smoothing: 0.75, wave_mystery: 0, modwavealphabyvolume: 0, modwavealphastart: 0.75, modwavealphaend: 0.95, wave_r: 1, wave_g: 1, wave_b: 1, wave_x: 0.5, wave_y: 0.5, wave_brighten: 1, mv_x: 12, mv_y: 9, mv_dx: 0, mv_dy: 0, mv_l: 0.9, mv_r: 1, mv_g: 1, mv_b: 1, mv_a: 1, warpanimspeed: 1, warpscale: 1, zoomexp: 1, zoom: 1, rot: 0, cx: 0.5, cy: 0.5, dx: 0, dy: 0, warp: 1, sx: 1, sy: 1, ob_size: 0.01, ob_r: 0, ob_g: 0, ob_b: 0, ob_a: 0, ib_size: 0.01, ib_r: 0.25, ib_g: 0.25, ib_b: 0.25, ib_a: 0 }, this.shapeBaseValsDefaults = { enabled: 0, sides: 4, additive: 0, thickoutline: 0, textured: 0, num_inst: 1, tex_zoom: 1, tex_ang: 0, x: 0.5, y: 0.5, rad: 0.1, ang: 0, r: 1, g: 0, b: 0, a: 1, r2: 0, g2: 1, b2: 0, a2: 0, border_r: 1, border_g: 1, border_b: 1, border_a: 0.1 }, this.waveBaseValsDefaults = { enabled: 0, samples: 512, sep: 0, scaling: 1, smoothing: 0.5, r: 1, g: 1, b: 1, a: 1, spectrum: 0, usedots: 0, thick: 0, additive: 0 }, this.renderer = new st(r2, this.audio, s3);
            }
            var e2, i2, s2;
            return e2 = t2, (i2 = [{ key: "connectAudio", value: function(t3) {
              this.audioNode = t3, this.audio.connectAudio(t3);
            } }, { key: "disconnectAudio", value: function(t3) {
              this.audio.disconnectAudio(t3);
            } }, { key: "loadPreset", value: function(t3) {
              var e3 = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : 0, i3 = Object.assign({}, t3);
              i3.baseVals = Object.assign({}, this.baseValsDefaults, i3.baseVals);
              for (var s3 = 0; s3 < i3.shapes.length; s3++) i3.shapes[s3].baseVals = Object.assign({}, this.shapeBaseValsDefaults, i3.shapes[s3].baseVals);
              for (var r2 = 0; r2 < i3.waves.length; r2++) i3.waves[r2].baseVals = Object.assign({}, this.waveBaseValsDefaults, i3.waves[r2].baseVals);
              if ("function" != typeof i3.init_eqs) {
                i3.init_eqs = new Function("a", "".concat(i3.init_eqs_str, " return a;")), i3.frame_eqs = new Function("a", "".concat(i3.frame_eqs_str, " return a;")), i3.pixel_eqs_str && "" !== i3.pixel_eqs_str ? i3.pixel_eqs = new Function("a", "".concat(i3.pixel_eqs_str, " return a;")) : i3.pixel_eqs = "";
                for (var a2 = 0; a2 < i3.shapes.length; a2++) 0 !== i3.shapes[a2].baseVals.enabled && (i3.shapes[a2] = Object.assign({}, i3.shapes[a2], { init_eqs: new Function("a", "".concat(i3.shapes[a2].init_eqs_str, " return a;")), frame_eqs: new Function("a", "".concat(i3.shapes[a2].frame_eqs_str, " return a;")) }));
                for (var h2 = 0; h2 < i3.waves.length; h2++) if (0 !== i3.waves[h2].baseVals.enabled) {
                  var o2 = { init_eqs: new Function("a", "".concat(i3.waves[h2].init_eqs_str, " return a;")), frame_eqs: new Function("a", "".concat(i3.waves[h2].frame_eqs_str, " return a;")) };
                  i3.waves[h2].point_eqs_str && "" !== i3.waves[h2].point_eqs_str ? o2.point_eqs = new Function("a", "".concat(i3.waves[h2].point_eqs_str, " return a;")) : o2.point_eqs = "", i3.waves[h2] = Object.assign({}, i3.waves[h2], o2);
                }
              }
              this.renderer.loadPreset(i3, e3);
            } }, { key: "loadExtraImages", value: function(t3) {
              this.renderer.loadExtraImages(t3);
            } }, { key: "setRendererSize", value: function(t3, e3) {
              var i3 = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {};
              this.renderer.setRendererSize(t3, e3, i3);
            } }, { key: "setInternalMeshSize", value: function(t3, e3) {
              this.renderer.setInternalMeshSize(t3, e3);
            } }, { key: "setOutputAA", value: function(t3) {
              this.renderer.setOutputAA(t3);
            } }, { key: "render", value: function(t3) {
              this.renderer.render(t3);
            } }, { key: "launchSongTitleAnim", value: function(t3) {
              this.renderer.launchSongTitleAnim(t3);
            } }, { key: "toDataURL", value: function() {
              return this.renderer.toDataURL();
            } }, { key: "warpBufferToDataURL", value: function() {
              return this.renderer.warpBufferToDataURL();
            } }]) && rt(e2.prototype, i2), s2 && rt(e2, s2), t2;
          })();
          function ht(t2, e2) {
            for (var i2 = 0; i2 < e2.length; i2++) {
              var s2 = e2[i2];
              s2.enumerable = s2.enumerable || false, s2.configurable = true, "value" in s2 && (s2.writable = true), Object.defineProperty(t2, s2.key, s2);
            }
          }
          i.d(e, "default", function() {
            return ot;
          });
          var ot = (function() {
            function t2() {
              !(function(t3, e3) {
                if (!(t3 instanceof e3)) throw new TypeError("Cannot call a class as a function");
              })(this, t2);
            }
            var e2, i2, s2;
            return e2 = t2, s2 = [{ key: "createVisualizer", value: function(t3, e3, i3) {
              return new at(t3, e3, i3);
            } }], (i2 = null) && ht(e2.prototype, i2), s2 && ht(e2, s2), t2;
          })();
        }]);
      });
    }
  });
  return require_butterchurn_min();
})();
