/**
 *
 * Color picker
 * Author: Stefan Petre www.eyecon.ro
 * 
 * Dual licensed under the MIT and GPL licenses
 * 
 */

(function ($) {
	var ColorPicker = function () {
		var
			ids = {},
			inAction,
			charMin = 65,
			visible,
			tpl = '<div class="colorpicker"><div class="colorpicker_color"><div><div></div></div></div><div class="colorpicker_hue"><div></div></div><div class="colorpicker_new_color"></div><div class="colorpicker_current_color"></div><div class="colorpicker_hex"><input type="text" maxlength="6" size="6" /></div><div class="colorpicker_rgb_r colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_rgb_g colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_rgb_b colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_h colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_s colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_b colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_submit"></div></div>',
			defaults = {
				eventName: 'click',
				onShow: function () {},
				onBeforeShow: function(){},
				onHide: function () {},
				onChange: function () {},
				onSubmit: function () {},
				color: 'ff0000',
				livePreview: true,
				flat: false
			},
			fillRGBFields = function  (hsb, cal) {
				var rgb = HSBToRGB(hsb);
				$(cal).data('colorpicker').fields
					.eq(1).val(rgb.r).end()
					.eq(2).val(rgb.g).end()
					.eq(3).val(rgb.b).end();
			},
			fillHSBFields = function  (hsb, cal) {
				$(cal).data('colorpicker').fields
					.eq(4).val(hsb.h).end()
					.eq(5).val(hsb.s).end()
					.eq(6).val(hsb.b).end();
			},
			fillHexFields = function (hsb, cal) {
				$(cal).data('colorpicker').fields
					.eq(0).val(HSBToHex(hsb)).end();
			},
			setSelector = function (hsb, cal) {
				$(cal).data('colorpicker').selector.css('backgroundColor', '#' + HSBToHex({h: hsb.h, s: 100, b: 100}));
				$(cal).data('colorpicker').selectorIndic.css({
					left: parseInt(150 * hsb.s/100, 10),
					top: parseInt(150 * (100-hsb.b)/100, 10)
				});
			},
			setHue = function (hsb, cal) {
				$(cal).data('colorpicker').hue.css('top', parseInt(150 - 150 * hsb.h/360, 10));
			},
			setCurrentColor = function (hsb, cal) {
				$(cal).data('colorpicker').currentColor.css('backgroundColor', '#' + HSBToHex(hsb));
			},
			setNewColor = function (hsb, cal) {
				$(cal).data('colorpicker').newColor.css('backgroundColor', '#' + HSBToHex(hsb));
			},
			keyDown = function (ev) {
				var pressedKey = ev.charCode || ev.keyCode || -1;
				if ((pressedKey > charMin && pressedKey <= 90) || pressedKey == 32) {
					return false;
				}
				var cal = $(this).parent().parent();
				if (cal.data('colorpicker').livePreview === true) {
					change.apply(this);
				}
			},
			change = function (ev) {
				var cal = $(this).parent().parent(), col;
				if (this.parentNode.className.indexOf('_hex') > 0) {
					cal.data('colorpicker').color = col = HexToHSB(fixHex(this.value));
				} else if (this.parentNode.className.indexOf('_hsb') > 0) {
					cal.data('colorpicker').color = col = fixHSB({
						h: parseInt(cal.data('colorpicker').fields.eq(4).val(), 10),
						s: parseInt(cal.data('colorpicker').fields.eq(5).val(), 10),
						b: parseInt(cal.data('colorpicker').fields.eq(6).val(), 10)
					});
				} else {
					cal.data('colorpicker').color = col = RGBToHSB(fixRGB({
						r: parseInt(cal.data('colorpicker').fields.eq(1).val(), 10),
						g: parseInt(cal.data('colorpicker').fields.eq(2).val(), 10),
						b: parseInt(cal.data('colorpicker').fields.eq(3).val(), 10)
					}));
				}
				if (ev) {
					fillRGBFields(col, cal.get(0));
					fillHexFields(col, cal.get(0));
					fillHSBFields(col, cal.get(0));
				}
				setSelector(col, cal.get(0));
				setHue(col, cal.get(0));
				setNewColor(col, cal.get(0));
				cal.data('colorpicker').onChange.apply(cal, [col, HSBToHex(col), HSBToRGB(col)]);
			},
			blur = function (ev) {
				var cal = $(this).parent().parent();
				cal.data('colorpicker').fields.parent().removeClass('colorpicker_focus');
			},
			focus = function () {
				charMin = this.parentNode.className.indexOf('_hex') > 0 ? 70 : 65;
				$(this).parent().parent().data('colorpicker').fields.parent().removeClass('colorpicker_focus');
				$(this).parent().addClass('colorpicker_focus');
			},
			downIncrement = function (ev) {
				var field = $(this).parent().find('input').focus();
				var current = {
					el: $(this).parent().addClass('colorpicker_slider'),
					max: this.parentNode.className.indexOf('_hsb_h') > 0 ? 360 : (this.parentNode.className.indexOf('_hsb') > 0 ? 100 : 255),
					y: ev.pageY,
					field: field,
					val: parseInt(field.val(), 10),
					preview: $(this).parent().parent().data('colorpicker').livePreview					
				};
				$(document).bind('mouseup', current, upIncrement);
				$(document).bind('mousemove', current, moveIncrement);
			},
			moveIncrement = function (ev) {
				ev.data.field.val(Math.max(0, Math.min(ev.data.max, parseInt(ev.data.val + ev.pageY - ev.data.y, 10))));
				if (ev.data.preview) {
					change.apply(ev.data.field.get(0), [true]);
				}
				return false;
			},
			upIncrement = function (ev) {
				change.apply(ev.data.field.get(0), [true]);
				ev.data.el.removeClass('colorpicker_slider').find('input').focus();
				$(document).unbind('mouseup', upIncrement);
				$(document).unbind('mousemove', moveIncrement);
				return false;
			},
			downHue = function (ev) {
				var current = {
					cal: $(this).parent(),
					y: $(this).offset().top
				};
				current.preview = current.cal.data('colorpicker').livePreview;
				$(document).bind('mouseup', current, upHue);
				$(document).bind('mousemove', current, moveHue);
			},
			moveHue = function (ev) {
				change.apply(
					ev.data.cal.data('colorpicker')
						.fields
						.eq(4)
						.val(parseInt(360*(150 - Math.max(0,Math.min(150,(ev.pageY - ev.data.y))))/150, 10))
						.get(0),
					[ev.data.preview]
				);
				return false;
			},
			upHue = function (ev) {
				fillRGBFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
				fillHexFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
				$(document).unbind('mouseup', upHue);
				$(document).unbind('mousemove', moveHue);
				return false;
			},
			downSelector = function (ev) {
				var current = {
					cal: $(this).parent(),
					pos: $(this).offset()
				};
				current.preview = current.cal.data('colorpicker').livePreview;
				$(document).bind('mouseup', current, upSelector);
				$(document).bind('mousemove', current, moveSelector);
			},
			moveSelector = function (ev) {
				change.apply(
					ev.data.cal.data('colorpicker')
						.fields
						.eq(6)
						.val(parseInt(100*(150 - Math.max(0,Math.min(150,(ev.pageY - ev.data.pos.top))))/150, 10))
						.end()
						.eq(5)
						.val(parseInt(100*(Math.max(0,Math.min(150,(ev.pageX - ev.data.pos.left))))/150, 10))
						.get(0),
					[ev.data.preview]
				);
				return false;
			},
			upSelector = function (ev) {
				fillRGBFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
				fillHexFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
				$(document).unbind('mouseup', upSelector);
				$(document).unbind('mousemove', moveSelector);
				return false;
			},
			enterSubmit = function (ev) {
				$(this).addClass('colorpicker_focus');
			},
			leaveSubmit = function (ev) {
				$(this).removeClass('colorpicker_focus');
			},
			clickSubmit = function (ev) {
				var cal = $(this).parent();
				var col = cal.data('colorpicker').color;
				cal.data('colorpicker').origColor = col;
				setCurrentColor(col, cal.get(0));
				cal.data('colorpicker').onSubmit(col, HSBToHex(col), HSBToRGB(col), cal.data('colorpicker').el);
			},
			show = function (ev) {
				var cal = $('#' + $(this).data('colorpickerId'));
				cal.data('colorpicker').onBeforeShow.apply(this, [cal.get(0)]);
				var pos = $(this).offset();
				var viewPort = getViewport();
				var top = pos.top + this.offsetHeight;
				var left = pos.left;
				if (top + 176 > viewPort.t + viewPort.h) {
					top -= this.offsetHeight + 176;
				}
				if (left + 356 > viewPort.l + viewPort.w) {
					left -= 356;
				}
				cal.css({left: left + 'px', top: top + 'px'});
				if (cal.data('colorpicker').onShow.apply(this, [cal.get(0)]) != false) {
					cal.show();
				}
				$(document).bind('mousedown', {cal: cal}, hide);
				return false;
			},
			hide = function (ev) {
				if (!isChildOf(ev.data.cal.get(0), ev.target, ev.data.cal.get(0))) {
					if (ev.data.cal.data('colorpicker').onHide.apply(this, [ev.data.cal.get(0)]) != false) {
						ev.data.cal.hide();
					}
					$(document).unbind('mousedown', hide);
				}
			},
			isChildOf = function(parentEl, el, container) {
				if (parentEl == el) {
					return true;
				}
				if (parentEl.contains) {
					return parentEl.contains(el);
				}
				if ( parentEl.compareDocumentPosition ) {
					return !!(parentEl.compareDocumentPosition(el) & 16);
				}
				var prEl = el.parentNode;
				while(prEl && prEl != container) {
					if (prEl == parentEl)
						return true;
					prEl = prEl.parentNode;
				}
				return false;
			},
			getViewport = function () {
				var m = document.compatMode == 'CSS1Compat';
				return {
					l : window.pageXOffset || (m ? document.documentElement.scrollLeft : document.body.scrollLeft),
					t : window.pageYOffset || (m ? document.documentElement.scrollTop : document.body.scrollTop),
					w : window.innerWidth || (m ? document.documentElement.clientWidth : document.body.clientWidth),
					h : window.innerHeight || (m ? document.documentElement.clientHeight : document.body.clientHeight)
				};
			},
			fixHSB = function (hsb) {
				return {
					h: Math.min(360, Math.max(0, hsb.h)),
					s: Math.min(100, Math.max(0, hsb.s)),
					b: Math.min(100, Math.max(0, hsb.b))
				};
			}, 
			fixRGB = function (rgb) {
				return {
					r: Math.min(255, Math.max(0, rgb.r)),
					g: Math.min(255, Math.max(0, rgb.g)),
					b: Math.min(255, Math.max(0, rgb.b))
				};
			},
			fixHex = function (hex) {
				var len = 6 - hex.length;
				if (len > 0) {
					var o = [];
					for (var i=0; i<len; i++) {
						o.push('0');
					}
					o.push(hex);
					hex = o.join('');
				}
				return hex;
			}, 
			HexToRGB = function (hex) {
				var hex = parseInt(((hex.indexOf('#') > -1) ? hex.substring(1) : hex), 16);
				return {r: hex >> 16, g: (hex & 0x00FF00) >> 8, b: (hex & 0x0000FF)};
			},
			HexToHSB = function (hex) {
				return RGBToHSB(HexToRGB(hex));
			},
			RGBToHSB = function (rgb) {
				var hsb = {
					h: 0,
					s: 0,
					b: 0
				};
				var min = Math.min(rgb.r, rgb.g, rgb.b);
				var max = Math.max(rgb.r, rgb.g, rgb.b);
				var delta = max - min;
				hsb.b = max;
				if (max != 0) {
					
				}
				hsb.s = max != 0 ? 255 * delta / max : 0;
				if (hsb.s != 0) {
					if (rgb.r == max) {
						hsb.h = (rgb.g - rgb.b) / delta;
					} else if (rgb.g == max) {
						hsb.h = 2 + (rgb.b - rgb.r) / delta;
					} else {
						hsb.h = 4 + (rgb.r - rgb.g) / delta;
					}
				} else {
					hsb.h = -1;
				}
				hsb.h *= 60;
				if (hsb.h < 0) {
					hsb.h += 360;
				}
				hsb.s *= 100/255;
				hsb.b *= 100/255;
				return hsb;
			},
			HSBToRGB = function (hsb) {
				var rgb = {};
				var h = Math.round(hsb.h);
				var s = Math.round(hsb.s*255/100);
				var v = Math.round(hsb.b*255/100);
				if(s == 0) {
					rgb.r = rgb.g = rgb.b = v;
				} else {
					var t1 = v;
					var t2 = (255-s)*v/255;
					var t3 = (t1-t2)*(h%60)/60;
					if(h==360) h = 0;
					if(h<60) {rgb.r=t1;	rgb.b=t2; rgb.g=t2+t3}
					else if(h<120) {rgb.g=t1; rgb.b=t2;	rgb.r=t1-t3}
					else if(h<180) {rgb.g=t1; rgb.r=t2;	rgb.b=t2+t3}
					else if(h<240) {rgb.b=t1; rgb.r=t2;	rgb.g=t1-t3}
					else if(h<300) {rgb.b=t1; rgb.g=t2;	rgb.r=t2+t3}
					else if(h<360) {rgb.r=t1; rgb.g=t2;	rgb.b=t1-t3}
					else {rgb.r=0; rgb.g=0;	rgb.b=0}
				}
				return {r:Math.round(rgb.r), g:Math.round(rgb.g), b:Math.round(rgb.b)};
			},
			RGBToHex = function (rgb) {
				var hex = [
					rgb.r.toString(16),
					rgb.g.toString(16),
					rgb.b.toString(16)
				];
				$.each(hex, function (nr, val) {
					if (val.length == 1) {
						hex[nr] = '0' + val;
					}
				});
				return hex.join('');
			},
			HSBToHex = function (hsb) {
				return RGBToHex(HSBToRGB(hsb));
			},
			restoreOriginal = function () {
				var cal = $(this).parent();
				var col = cal.data('colorpicker').origColor;
				cal.data('colorpicker').color = col;
				fillRGBFields(col, cal.get(0));
				fillHexFields(col, cal.get(0));
				fillHSBFields(col, cal.get(0));
				setSelector(col, cal.get(0));
				setHue(col, cal.get(0));
				setNewColor(col, cal.get(0));
			};
		return {
			init: function (opt) {
				opt = $.extend({}, defaults, opt||{});
				if (typeof opt.color == 'string') {
					opt.color = HexToHSB(opt.color);
				} else if (opt.color.r != undefined && opt.color.g != undefined && opt.color.b != undefined) {
					opt.color = RGBToHSB(opt.color);
				} else if (opt.color.h != undefined && opt.color.s != undefined && opt.color.b != undefined) {
					opt.color = fixHSB(opt.color);
				} else {
					return this;
				}
				return this.each(function () {
					if (!$(this).data('colorpickerId')) {
						var options = $.extend({}, opt);
						options.origColor = opt.color;
						var id = 'collorpicker_' + parseInt(Math.random() * 1000);
						$(this).data('colorpickerId', id);
						var cal = $(tpl).attr('id', id);
						if (options.flat) {
							cal.appendTo(this).show();
						} else {
							cal.appendTo(document.body);
						}
						options.fields = cal
											.find('input')
												.bind('keyup', keyDown)
												.bind('change', change)
												.bind('blur', blur)
												.bind('focus', focus);
						cal
							.find('span').bind('mousedown', downIncrement).end()
							.find('>div.colorpicker_current_color').bind('click', restoreOriginal);
						options.selector = cal.find('div.colorpicker_color').bind('mousedown', downSelector);
						options.selectorIndic = options.selector.find('div div');
						options.el = this;
						options.hue = cal.find('div.colorpicker_hue div');
						cal.find('div.colorpicker_hue').bind('mousedown', downHue);
						options.newColor = cal.find('div.colorpicker_new_color');
						options.currentColor = cal.find('div.colorpicker_current_color');
						cal.data('colorpicker', options);
						cal.find('div.colorpicker_submit')
							.bind('mouseenter', enterSubmit)
							.bind('mouseleave', leaveSubmit)
							.bind('click', clickSubmit);
						fillRGBFields(options.color, cal.get(0));
						fillHSBFields(options.color, cal.get(0));
						fillHexFields(options.color, cal.get(0));
						setHue(options.color, cal.get(0));
						setSelector(options.color, cal.get(0));
						setCurrentColor(options.color, cal.get(0));
						setNewColor(options.color, cal.get(0));
						if (options.flat) {
							cal.css({
								position: 'relative',
								display: 'block'
							});
						} else {
							$(this).bind(options.eventName, show);
						}
					}
				});
			},
			showPicker: function() {
				return this.each( function () {
					if ($(this).data('colorpickerId')) {
						show.apply(this);
					}
				});
			},
			hidePicker: function() {
				return this.each( function () {
					if ($(this).data('colorpickerId')) {
						$('#' + $(this).data('colorpickerId')).hide();
					}
				});
			},
			setColor: function(col) {
				if (typeof col == 'string') {
					col = HexToHSB(col);
				} else if (col.r != undefined && col.g != undefined && col.b != undefined) {
					col = RGBToHSB(col);
				} else if (col.h != undefined && col.s != undefined && col.b != undefined) {
					col = fixHSB(col);
				} else {
					return this;
				}
				return this.each(function(){
					if ($(this).data('colorpickerId')) {
						var cal = $('#' + $(this).data('colorpickerId'));
						cal.data('colorpicker').color = col;
						cal.data('colorpicker').origColor = col;
						fillRGBFields(col, cal.get(0));
						fillHSBFields(col, cal.get(0));
						fillHexFields(col, cal.get(0));
						setHue(col, cal.get(0));
						setSelector(col, cal.get(0));
						setCurrentColor(col, cal.get(0));
						setNewColor(col, cal.get(0));
					}
				});
			}
		};
	}();
	$.fn.extend({
		ColorPicker: ColorPicker.init,
		ColorPickerHide: ColorPicker.hidePicker,
		ColorPickerShow: ColorPicker.showPicker,
		ColorPickerSetColor: ColorPicker.setColor
	});
})(jQuery)
;
/*global Image, $, CropTool, window, ImageServer, CoordinateManager, CropManager, alert, 
	PersistenceManager, TileManager */

/**
 * @fileoverview JavaScript for constructing and managing the control panel (bottom-left).
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */



var ControlManager = {};
ControlManager.mode = "move";

ControlManager.BASE_SIDE = 32;
ControlManager.FILL = "#424242";
ControlManager.STROKE = "#606060"; // "#919191";

ControlManager.hideCropControls = function()
{
	if (ControlManager.cropControls !== undefined)
	{
		ControlManager.cropControls.frame.remove();
		ControlManager.cropControls.frameIcon.remove();
		
		if (CropTool.editable)
		{
			ControlManager.cropControls.rotation.remove();
			ControlManager.cropControls.clockIcon.remove();
			ControlManager.cropControls.counterIcon.remove();
			ControlManager.cropControls.rotationBar.remove();
			ControlManager.cropControls.rotationSlider.remove();
			ControlManager.cropControls.color.remove();
			ControlManager.cropControls.colorIcon.remove();
			ControlManager.cropControls.save.remove();
			ControlManager.cropControls.saveIcon.remove();
		}

		if (ControlManager.cropControls.dimInfo !== undefined)
		{
			ControlManager.cropControls.dimInfo.remove();
			ControlManager.cropControls.dimText.remove();
		}

		if (ControlManager.cropControls.colorInfo !== undefined)
		{
			ControlManager.cropControls.colorInfo.remove();

			ControlManager.cropControls.black.remove();
			ControlManager.cropControls.blue.remove();
			ControlManager.cropControls.brown.remove();
			ControlManager.cropControls.green.remove();
			ControlManager.cropControls.orange.remove();
			ControlManager.cropControls.red.remove();
			ControlManager.cropControls.violet.remove();
			ControlManager.cropControls.yellow.remove();
			ControlManager.cropControls.white.remove();
		}
		
		delete ControlManager.cropControls;
	}
};

ControlManager.showCropControls = function(crop)
{
	if (ControlManager.cropControls === undefined)
	{
		var controls = {};
		
		var base = ControlManager.BASE_SIDE;

		var frameInfo = function(event)
		{
			if (ControlManager.cropControls.dimInfo !== undefined)
			{
				ControlManager.cropControls.dimInfo.remove();
				ControlManager.cropControls.dimText.remove();
			}

			var y = $(CropTool.rootDiv).height() - base - 40;

			var pathString = "M 20 " + y;
			pathString += "L 80 " + y;
			pathString += "C 80 " + y + " 90 " + y + " 90 " + (y + 10);
			pathString += "L 90 " + (y + 20);
			pathString += "C 90 " + (y + 20) + " 90 " + (y + 30) + " 80 " + (y + 30);
			pathString += "L 20 " + (y + 30);

			pathString += "L 10 " + (y + 40);
			pathString += "L 10 " + (y + 10);
			pathString += "C 10 " + (y + 10) + " 10 " + y + " 20 " + y;
			
			var dimInfo = CropTool.paper.path(pathString);
			dimInfo.attr("fill", "#444");
			dimInfo.attr("stroke", "none");
			dimInfo.attr("fill-opacity", 0.75);
			ControlManager.cropControls.dimInfo = dimInfo;	
			ControlManager.cropControls.dimInfo.toFront();
			
			var crop = CropManager.selectedCrop;

			var dimString = Math.floor(ImageServer.details.width * crop.width) + "x";
			dimString += Math.floor(ImageServer.details.height * crop.height) + "\n";
			dimString += Math.floor(ImageServer.details.width * (crop.cx - (crop.width / 2))) + ", ";
			dimString += Math.floor(ImageServer.details.height * (crop.cy - (crop.height / 2)));

			var dimText = CropTool.paper.text(50, y + 15, dimString);
			dimText.attr("fill", "#fff");
			dimText.attr("stroke", "none");
			ControlManager.cropControls.dimText = dimText;	
			ControlManager.cropControls.dimText.toFront();
		};
		
		var frame = CropTool.paper.rect(0, base, base, base);
		frame.click(frameInfo);
		frame.attr("fill", ControlManager.FILL);
		frame.attr("stroke", ControlManager.STROKE);
		controls.frame = frame; 
		
		var frameIcon = CropTool.paper.image(Site.iconPath() + "ruler-24.png", 8, 8, 24, 24);
		frameIcon.click(frameInfo);
		controls.frameIcon = frameIcon; 

		if (CropTool.editable)
		{
			var rotation = CropTool.paper.rect(base, base, base * 6, base);
			rotation.attr("fill", ControlManager.FILL);
			rotation.attr("stroke", ControlManager.STROKE);
			controls.rotation = rotation;	

			var clockIcon = CropTool.paper.image(Site.iconPath() + "clock-16.png", (base * 6) + 8, (base * 6) + 9, 16, 16);
			clockIcon.click(function(event)
			{
				var rotation = CropManager.selectedCrop.rotation;

				rotation = Math.floor(rotation + 1);
			
				if (rotation >= 0 && rotation < 360)
				{
					CropManager.selectedCrop.rotation = rotation;
					CropManager.updatePosition();
					ControlManager.cropControls.rotationSlider.setRotation(rotation);
				}
				else
					alert("Cannot rotate further.");
			});
			controls.clockIcon = clockIcon; 

			var counterIcon = CropTool.paper.image(Site.iconPath() + "counter-16.png", base + 8, (base * 6) + 9, 16, 16);
			counterIcon.click(function(event)
			{
				var rotation = CropManager.selectedCrop.rotation;

				rotation = Math.floor(rotation - 1);
			
				if (rotation >= 0 && rotation < 360)
				{
					CropManager.selectedCrop.rotation = rotation;
					CropManager.updatePosition();
					ControlManager.cropControls.rotationSlider.setRotation(rotation);
				}
				else
					alert("Cannot rotate further.");
			});
			controls.counterIcon = counterIcon; 

			var rotationBar = CropTool.paper.rect(2 * base, 0, (base * 4), 20, 5);
			rotationBar.attr("fill", "#222");
			rotationBar.attr("stroke", ControlManager.STROKE);
			controls.rotationBar = rotationBar; 

			var rotationSlider = CropTool.paper.rect((2 * base) + 1, 0, 10, 18, 4);
			rotationSlider.attr("fill", "#800");
			rotationSlider.attr("stroke", "none");

			rotationSlider.setRotation = function(degrees)
			{
				var x = rotationBar.attr("x") + 1;
				var ratio = degrees / 360;
				var width = rotationBar.attr("width") - rotationSlider.attr("width") - 1;
		
				rotationSlider.attr("x", x + Math.floor(ratio * width));
			
				TileManager.updatePosition();
				CropManager.updatePosition();		
				ControlManager.toFront();
			}

			var start = function() 
			{
				rotationSlider.ox = rotationSlider.attr("x");
			};

			var move = function(dx, dy) 
			{
				var x = Math.floor(rotationSlider.ox + dx);
		
				if (x > rotationBar.attr("x") && x + rotationSlider.attr("width") < rotationBar.attr("x") + rotationBar.attr("width") - 1)
				{
					rotationSlider.attr("x", x);
			
					var delta = Math.floor(x - rotationBar.attr("x"));
					var width = Math.floor(rotationBar.attr("width") - rotationSlider.attr("width") - 1);
					var degrees = Math.round((delta / width) * 360);
				
					if (degrees > 359 || degrees < 0)
						degrees = 0;

					CropManager.selectedCrop.rotation = degrees;
					TileManager.updatePosition();
					CropManager.updatePosition();		
					ControlManager.toFront();
				}
			};

			var up = function () 
			{

			};
	
			rotationSlider.drag(move, start, up);

			controls.rotationSlider = rotationSlider;	

			var colorClick = function(event)
			{
				if (ControlManager.cropControls.colorInfo !== undefined)
				{
					ControlManager.toFront();
				}

				var setCropColor = function(color)
				{
					CropManager.selectedCrop.color = color;
						
					CropManager.updatePosition();
					ControlManager.toFront();
				};
					
				var x = base * 7.5;
				var y = $(CropTool.rootDiv).height() - base - 100;

				var pathString = "M " + (x + 10) + " " + y;
				pathString += "L " + (x + 80) + " " + y;
				pathString += "C " + (x + 80) + " " + y + " " + (x + 90) + " " + y + " " + (x + 90) + " " + (y + 10);
				pathString += "L " + (x + 90) + " " + (y + 80);
				pathString += "C " + (x + 90) + " " + (y + 80) + " " + (x + 90) + " " + (y + 90) + " " + (x + 80) + " " + (y + 90);
				pathString += "L " + (x + 10) + " " + (y + 90);
				
				pathString += "L " + x + " " + (y + 100);
				pathString += "L " + x + " " + (y + 10);
				pathString += "C " + x + " " + (y + 10) + " " + x + " " + y + " " + (x + 10) + " " + y;
			
				var colorInfo = CropTool.paper.path(pathString);
				colorInfo.attr("fill", "#444");
				colorInfo.attr("stroke", "none");
				colorInfo.attr("fill-opacity", 0.75);
				ControlManager.cropControls.colorInfo = colorInfo;	
				ControlManager.cropControls.colorInfo.toFront();

				controls.black = CropTool.paper.rect(x + 10, y + 10, 20, 20);
				controls.black.attr("fill", "#000");
				controls.black.attr("stroke", "none");
				controls.black.click(function(event)
				{
					setCropColor("#000000");
				});
				controls.black.toFront();
					
				controls.blue = CropTool.paper.rect(x + 35, y + 10, 20, 20);
				controls.blue.attr("fill", "#1F75FE");
				controls.blue.attr("stroke", "none");
				controls.blue.click(function(event)
				{
					setCropColor("#1F75FE");
				});
				controls.blue.toFront();

				controls.brown = CropTool.paper.rect(x + 60, y + 10, 20, 20);
				controls.brown.attr("fill", "#B4674D");
				controls.brown.attr("stroke", "none");
				controls.brown.click(function(event)
				{
					setCropColor("#B4674D");
				});
				controls.brown.toFront();

				controls.green = CropTool.paper.rect(x + 10, y + 35, 20, 20);
				controls.green.attr("fill", "#1CAC78");
				controls.green.attr("stroke", "none");
				controls.green.click(function(event)
				{
					setCropColor("#1CAC78");
				});
				controls.green.toFront();

				controls.orange = CropTool.paper.rect(x + 35, y + 35, 20, 20);
				controls.orange.attr("fill", "#FF7538");
				controls.orange.attr("stroke", "none");
				controls.orange.click(function(event)
				{
					setCropColor("#FF7538");
				});
				controls.orange.toFront();

				controls.red = CropTool.paper.rect(x + 60, y + 35, 20, 20);
				controls.red.attr("fill", "#EE204D");
				controls.red.attr("stroke", "none");
				controls.red.click(function(event)
				{
					setCropColor("#EE204D");
				});
				controls.red.toFront();

				controls.violet = CropTool.paper.rect(x + 10, y + 60, 20, 20);
				controls.violet.attr("fill", "#926EAE");
				controls.violet.attr("stroke", "none");
				controls.violet.click(function(event)
				{
					setCropColor("#926EAE");
				});
				controls.violet.toFront();

				controls.yellow = CropTool.paper.rect(x + 35, y + 60, 20, 20);
				controls.yellow.attr("fill", "#FCE883");
				controls.yellow.attr("stroke", "none");
				controls.yellow.click(function(event)
				{
					setCropColor("#FCE883");
				});
				controls.yellow.toFront();

				controls.white = CropTool.paper.rect(x + 60, y + 60, 20, 20);
				controls.white.attr("fill", "#ffffff");
				controls.white.attr("stroke", "none");
				controls.white.click(function(event)
				{
					setCropColor("#ffffff");
				});
				controls.white.toFront();
			};
		
			var color = CropTool.paper.rect(base * 7, base, base, base);
			color.attr("fill", ControlManager.FILL);
			color.attr("stroke", ControlManager.STROKE);
			color.click(colorClick);
			controls.color = color; 
		
			var colorIcon = CropTool.paper.image(Site.iconPath() + "color-24.png", base, base, 24, 24);
			colorIcon.click(colorClick);
			controls.colorIcon = colorIcon; 

			var saveClick = function(event)
			{
				PersistenceManager.saveCrop(CropManager.selectedCrop);
			};

			var save = CropTool.paper.rect(base * 8, base, base, base);
			save.attr("fill", ControlManager.FILL);
			save.attr("stroke", ControlManager.STROKE);
			save.click(saveClick);
			controls.save = save;	

			var saveIcon = CropTool.paper.image(Site.iconPath() + "save-24.png", base, base, 24, 24);
			saveIcon.click(saveClick);
			controls.saveIcon = saveIcon;	
		}
		
		ControlManager.cropControls = controls;
	}

	var height = $(CropTool.rootDiv).height() - 1;

	var frame = ControlManager.cropControls.frame;
	frame.attr("y", height - ControlManager.BASE_SIDE);
	frame.toFront();

	ControlManager.cropControls.frameIcon.attr("y", frame.attr("y") + 4);
	ControlManager.cropControls.frameIcon.attr("x", frame.attr("x") + 4);
	ControlManager.cropControls.frameIcon.toFront();

	if (CropTool.editable)
	{
		var rotation = ControlManager.cropControls.rotation;
		rotation.attr("y", height - ControlManager.BASE_SIDE);
		rotation.toFront();
	
		ControlManager.cropControls.clockIcon.attr("y", rotation.attr("y") + 8);
		ControlManager.cropControls.counterIcon.attr("y", rotation.attr("y") + 8);

		ControlManager.cropControls.rotationBar.attr("y", rotation.attr("y") + 7);
		ControlManager.cropControls.rotationSlider.attr("y", rotation.attr("y") + 8);

		var color = ControlManager.cropControls.color;
		color.attr("y", height - ControlManager.BASE_SIDE);
		color.toFront();
	
		ControlManager.cropControls.colorIcon.attr("y", color.attr("y") + 4);
		ControlManager.cropControls.colorIcon.attr("x", color.attr("x") + 4);
		ControlManager.cropControls.colorIcon.toFront();
	
		var save = ControlManager.cropControls.save;
		save.attr("y", height - ControlManager.BASE_SIDE);
		save.toFront();

		ControlManager.cropControls.saveIcon.attr("y", save.attr("y") + 4);
		ControlManager.cropControls.saveIcon.attr("x", save.attr("x") + 4);
		ControlManager.cropControls.saveIcon.toFront();

		TileManager.updatePosition();
		CropManager.updatePosition();		
		ControlManager.toFront();
	}
};

ControlManager.updateRotation = function(degrees)
{
	if (ControlManager.controls.rotationSlider !== undefined)
	{
		var x = ControlManager.controls.rotationBar.attr("x") + 1;
		var ratio = degrees / 360;
		var width = ControlManager.controls.rotationBar.attr("width") - ControlManager.controls.rotationSlider.attr("width") - 1;
		
		ControlManager.controls.rotationSlider.attr("x", x + Math.floor(ratio * width));
	}
};

ControlManager.updateZoom = function(zoomLevel)
{
	if (ControlManager.controls !== undefined && ControlManager.controls.zoomSlider !== undefined)
	{
		var top = CoordinateManager.level_count - CoordinateManager.base_level;
		zoomLevel = zoomLevel - CoordinateManager.base_level;
		
		var y = ControlManager.controls.zoomBar.attr("y") + 1;
		var ratio = 1 - (zoomLevel / top);
		var height = ControlManager.controls.zoomBar.attr("height") - ControlManager.controls.zoomSlider.attr("height") - 2;

		ControlManager.controls.zoomSlider.attr("y", y + Math.floor(ratio * height));
		ControlManager.controls.zoomSlider.attr("x", ControlManager.controls.zoomBar.attr("x") + 1);
	}
};

/** 
 * Creates the control panel and binds the actions to the approriate widgets.
 */

ControlManager.initialize = function ()
{
	var height = $(CropTool.rootDiv).height() - 1;
	var width = $(CropTool.rootDiv).width() - 1;

	var controls = {};
		
	var base = ControlManager.BASE_SIDE;
    
    var mode = CropTool.paper.rect();
	// Draw the area for the move tool
	//var mode = CropTool.paper.rect(width - base, height - base, base, base);
	//mode.attr("fill", ControlManager.FILL);
	//mode.attr("stroke", ControlManager.STROKE);

	var toggleFunction = function(event)
	{
		var currentMode = ControlManager.mode;

		var icon = ControlManager.controls.modeIcon;	
		
		var modeIcon = null;

		if (currentMode === "move")
		{
			modeIcon = CropTool.paper.image(Site.iconPath() + "edit-24.png", icon.attr("x"), icon.attr("y"), 24, 24);

			CropManager.setEditable(true);
			CropManager.setDrawable(false);
		
			if (CropManager.selectedCrop !== null)
				MetadataManager.showCropDetails(CropManager.selectedCrop);

			ControlManager.mode = "edit";
		}
		else
		{
			modeIcon = CropTool.paper.image(Site.iconPath() + "move-24.png", icon.attr("x"), icon.attr("y"), 24, 24);

			MetadataManager.hideCropDetails();
			CropManager.setEditable(false);
			CropManager.setDrawable(false);
			
			ControlManager.mode = "move";
		}

		modeIcon.click(toggleFunction);
		modeIcon.toFront();
		controls.modeIcon = modeIcon;

		icon.remove();
	};

	mode.click(toggleFunction);

	controls.mode = mode;	
	
	//Add the move icon
	var modeIcon = CropTool.paper.image();
	modeIcon.click(toggleFunction);
	controls.modeIcon = modeIcon;	
	
	if (CropTool.editable && !CropTool.isCrop)
	{
		var create = CropTool.paper.rect(width - base, 0, base, base);
		create.attr("fill", ControlManager.FILL);
		create.attr("stroke", ControlManager.STROKE);

		var createFunction = function(event)
		{
			if (confirm("Create a new image detail using the current viewport?\n\nAll image details will be placed in 'My Image Details'.\nIf the image was opened from an Image Group the detail will also be placed there."))
				PersistenceManager.requestNewCrop();
		};
	
		create.click(createFunction);

		controls.create = create;	

		var createIcon = CropTool.paper.image(Site.iconPath() + "camera.png", width - base + 6, 7, 20, 20);
		createIcon.click(createFunction);
		controls.createIcon = createIcon;	
	}

	var rotation = CropTool.paper.rect(width - (base * 8), 0, (base * 6), base);
	rotation.attr("fill", ControlManager.FILL);
	rotation.attr("stroke", ControlManager.STROKE);
	controls.rotation = rotation;	

	var clockIcon = CropTool.paper.image(Site.iconPath() + "clock-16.png", width - (base * 3) + 8, 9, 16, 16);
	clockIcon.click(function(event)
	{
		var rotation = CoordinateManager.currentRotation();
		
		var newRotation = Math.floor(rotation + 1);
		
		if (newRotation < 360)
			CoordinateManager.setRotation(newRotation);
		else
			alert("Cannot rotate clockwise further.");
	});
	controls.clockIcon = clockIcon; 

	var counterIcon = CropTool.paper.image(Site.iconPath() + "counter-16.png", width - (base * 8) + 8, 9, 16, 16);
	counterIcon.click(function(event)
	{
		var rotation = CoordinateManager.currentRotation();
		
		var newRotation = Math.floor(rotation - 1);
		
		if (newRotation > 0)
			CoordinateManager.setRotation(newRotation);
		else
			alert("Cannot rotate counter-clockwise further.");
	});
	controls.counterIcon = counterIcon; 

	var rotationBar = CropTool.paper.rect(counterIcon.attr("x") + counterIcon.attr("width") + 8, 6, (base * 4), 20, 5);
	rotationBar.attr("fill", "#222");
	rotationBar.attr("stroke", ControlManager.STROKE);
	controls.rotationBar = rotationBar; 

	var rotationSlider = CropTool.paper.rect(rotationBar.attr("x") + 1, 7, 10, 18, 4);
	rotationSlider.attr("fill", "#800");
	rotationSlider.attr("stroke", "none");

	var start = function() 
	{
		rotationSlider.ox = rotationSlider.attr("x");
	};

	var move = function(dx, dy) 
	{
		var x = Math.floor(rotationSlider.ox + dx);
		
		if (x > rotationBar.attr("x") && x + rotationSlider.attr("width") < rotationBar.attr("x") + rotationBar.attr("width") - 1)
		{
			rotationSlider.attr("x", x);
			
			var delta = Math.floor(x - rotationBar.attr("x"));
			var width = Math.floor(rotationBar.attr("width") - rotationSlider.attr("width") - 1);
			var degrees = Math.round((delta / width) * 360);
			
			if (degrees > 359 || degrees < 0)
				degrees = 0;
				
			CoordinateManager.setRotation(Math.floor(degrees));
		}
	};

	var up = function () 
	{

	};
	
	rotationSlider.drag(move, start, up);

	controls.rotationSlider = rotationSlider;	

	var zoom = CropTool.paper.rect(width - base, base * 2, base, base * 6);
	zoom.attr("fill", ControlManager.FILL);
	zoom.attr("stroke", ControlManager.STROKE);
	controls.zoom = zoom;	

	var zoomInIcon = CropTool.paper.image(Site.iconPath() + "in-16.png", width - base + 8.5, (base * 2) + 8, 16, 16);
	zoomInIcon.click(function(event)
	{
		CoordinateManager.zoomIn();
	});
	controls.zoomInIcon = zoomInIcon;	

	var zoomOutIcon = CropTool.paper.image(Site.iconPath() + "out-16.png", width - base + 8.5, (base * 8) - 24, 16, 16);
	zoomOutIcon.click(function(event)
	{
		CoordinateManager.zoomOut();
	});
	controls.zoomOutIcon = zoomOutIcon; 

	var zoomBar = CropTool.paper.rect(width - base + 6, (base * 3), 20, base * 4, 5);
	zoomBar.attr("fill", "#222");
	zoomBar.attr("stroke", ControlManager.STROKE);
	controls.zoomBar = zoomBar; 

	var zoomSlider = CropTool.paper.rect(zoomBar.attr("x") + 1, zoomBar.attr("y") + 1, 18, 10, 4);
	zoomSlider.attr("fill", "#080");
	zoomSlider.attr("stroke", "none");

	var zoomStart = function() 
	{
		zoomSlider.oy = zoomSlider.attr("y");
	};

	var zoomMove = function(dx, dy) 
	{
		var y = Math.floor(zoomSlider.oy + dy);
		
		if (y > zoomBar.attr("y") && y + zoomSlider.attr("height") < zoomBar.attr("y") + zoomBar.attr("height") - 1)
		{
			zoomSlider.attr("y", y);
			
			var ratio = (zoomSlider.attr("y") + 1 - zoomBar.attr("y")) / (zoomBar.attr("height") - zoomSlider.attr("height"))

			zoomSlider.ratio = 1 - ratio;
		}
	};
	
	var zoomUp = function()
	{
		if (zoomSlider.ratio < 0)
			zoomSlider.ratio = 0;
		else if (zoomSlider.ratio > 1)
			zoomSlider.ratio = 1;
			
		var offset = Math.round((CoordinateManager.level_count - CoordinateManager.base_level) * zoomSlider.ratio);

		CoordinateManager.setZoomRatio(zoomSlider.ratio);
	};

	zoomSlider.drag(zoomMove, zoomStart, zoomUp);

	controls.zoomSlider = zoomSlider;	
		
	ControlManager.controls = controls;
	
	ControlManager.resize(width, height);
	MetadataManager.initializeDetails();
};

ControlManager.toFront = function()
{
	if (ControlManager.cropControls !== undefined)
	{
		ControlManager.cropControls.frame.toFront();
		ControlManager.cropControls.frameIcon.toFront();
		
		if (CropTool.editable)
		{
			ControlManager.cropControls.rotation.toFront();
			ControlManager.cropControls.clockIcon.toFront();
			ControlManager.cropControls.counterIcon.toFront();
			ControlManager.cropControls.rotationBar.toFront();
			ControlManager.cropControls.rotationSlider.toFront();
			ControlManager.cropControls.color.toFront();
			ControlManager.cropControls.colorIcon.toFront();
			ControlManager.cropControls.save.toFront();
			ControlManager.cropControls.saveIcon.toFront();
		}
		
		if (ControlManager.cropControls.dimInfo !== undefined)
		{
			ControlManager.cropControls.dimInfo.remove();
			ControlManager.cropControls.dimText.remove();
		}

		if (ControlManager.cropControls.colorInfo !== undefined)
		{
			ControlManager.cropControls.colorInfo.remove();
			ControlManager.cropControls.black.remove();
			ControlManager.cropControls.blue.remove();
			ControlManager.cropControls.brown.remove();
			ControlManager.cropControls.green.remove();
			ControlManager.cropControls.orange.remove();
			ControlManager.cropControls.red.remove();
			ControlManager.cropControls.violet.remove();
			ControlManager.cropControls.yellow.remove();
			ControlManager.cropControls.white.remove();
		}
	}

	if (ControlManager.controls !== undefined)
	{
		ControlManager.controls.mode.toFront(); 
		ControlManager.controls.modeIcon.toFront(); 

		if (ControlManager.controls.create !== undefined)
		{
			ControlManager.controls.create.toFront();	
			ControlManager.controls.createIcon.toFront();	
		}

		ControlManager.controls.rotation.toFront(); 
		ControlManager.controls.clockIcon.toFront();	
		ControlManager.controls.counterIcon.toFront();	
		ControlManager.controls.rotationBar.toFront();	
		ControlManager.controls.rotationSlider.toFront();	
		ControlManager.controls.zoom.toFront(); 
		ControlManager.controls.zoomInIcon.toFront();	
		ControlManager.controls.zoomOutIcon.toFront();	
		ControlManager.controls.zoomBar.toFront();	
		ControlManager.controls.zoomSlider.toFront();	
	}
};

ControlManager.viewportUpdated = function(left, top, level)
{
	ControlManager.updateZoom(level);
};

/**
 * Update the position and display of the contrl panel in light of resize events?
 */
 
ControlManager.resize = function (width, height)
{
	var base = ControlManager.BASE_SIDE;

	if (ControlManager.controls !== undefined)
	{
		ControlManager.controls.mode.attr({x: width - base, y: height - base});
		ControlManager.controls.modeIcon.attr({x: width - base + 5, y: height - base + 5});

		if (ControlManager.controls.create !== undefined)
		{
			ControlManager.controls.create.attr({x: width - base, y: 0});
			ControlManager.controls.createIcon.attr({x: width - base + 6, y: 7});
		}

		ControlManager.controls.rotation.attr({x: width - (base * 8), y: 0});
		ControlManager.controls.clockIcon.attr({x: width - (base * 3) + 7.5, y: 8.5});
		ControlManager.controls.counterIcon.attr({x: width - (base * 8) + 7.5, y: 8.5});
		ControlManager.controls.rotationBar.attr({x: ControlManager.controls.counterIcon.attr("x") + ControlManager.controls.counterIcon.attr("width") + 8, y: 6});

		ControlManager.updateRotation(CoordinateManager.currentRotation());

		ControlManager.controls.zoom.attr({x: width - base, y: base * 2});
		ControlManager.controls.zoomInIcon.attr({x: width - base + 8.5, y: (base * 2) + 8});
		ControlManager.controls.zoomOutIcon.attr({x: width - base + 8.5, y: (base * 8) - 24});
		ControlManager.controls.zoomBar.attr({x: width - base + 6, y: base * 3});

		ControlManager.updateZoom(CoordinateManager.current_level);
	}
};


/*global $, window, TileManager, CropManager */

/**
 * @fileoverview This file contains the code that manages the viewport of the image.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */


var CoordinateManager = {};

CoordinateManager.currentRotation = function()
{
	return CoordinateManager.glass.rotation;
};

/**
 * Sets up the data structures for tracking the viewport.
 */
 
CoordinateManager.initialize = function(frame_width, frame_height, levels)
{
    var viewport_width = $(CropTool.rootDiv).width() - 20;
    var viewport_height = $(CropTool.rootDiv).height() - 20;

    this.frame_width = frame_width;
    this.frame_height = frame_height;
    this.viewport_width = viewport_width;
    this.viewport_height = viewport_height;
    
    var image_width = frame_width;
    var image_height = frame_height;
    
    this.level_count = levels; // level = level_count => full zoom

    var viewport_max = viewport_width;
    var image_max = frame_width;
        
    if (viewport_height / viewport_width < frame_height / frame_width)
    {
        viewport_max = viewport_height;
        image_max = frame_height;
    }

    for (this.base_level = this.level_count; image_max > viewport_max && this.base_level > 0; this.base_level = this.base_level - 1)
    {
        image_max = image_max / 2;
        
        image_width = image_width / 2;
        image_height = image_height / 2;
    }

    $(window).resize(function()
    {
        CoordinateManager.viewport_width = $(CropTool.rootDiv).width() - 20;
        CoordinateManager.viewport_height = $(CropTool.rootDiv).height() - 20;
    });

    this.current_level = this.base_level;

    var width = ImageServer.details.width / CoordinateManager.zoomCoefficient();
    var height = ImageServer.details.height / CoordinateManager.zoomCoefficient();

    this.setViewport((width / 2), (height / 2), this.current_level);
};

CoordinateManager.currentActualViewport = function()
{
	var vp = {};
	
	var zoom = this.zoomCoefficient();
	
	vp.x = (0 - CoordinateManager.glass.attr("x")) * zoom;
	vp.y = (0 - CoordinateManager.glass.attr("y")) * zoom;
	
    vp.width = $(CropTool.rootDiv).width() * zoom;
    vp.height = $(CropTool.rootDiv).height() * zoom;

	//alert("Start crop with dimensions (" + vp.x + ", " + vp.y + " -- " + vp.width + "x" + vp.height + ")");

	return vp;
}
/**
 * Update the rotation of the viewport.
 */
 
CoordinateManager.setRotation = function(degrees)
{
    var viewport_width = $(CropTool.rootDiv).width() - 20;
    var viewport_height = $(CropTool.rootDiv).height() - 20;

    var vpcx = viewport_width / 2;
    var vpcy = viewport_height / 2;

    var delta = degrees - CoordinateManager.glass.rotation;
    CoordinateManager.glass.rotate(0 - CoordinateManager.glass.rotation);

    var cx = CoordinateManager.glass.attr("x") + (CoordinateManager.glass.attr("width") / 2);
    var cy = CoordinateManager.glass.attr("y") + (CoordinateManager.glass.attr("height") / 2);
                    
    var dx = cx - vpcx;
    var dy = cy - vpcy;

    var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
                    
    var current_angle = Math.atan2(dy, dx);
    var angle = (delta * Math.PI) / 180;
    
    var nx = vpcx + (Math.cos(angle + current_angle) * d) - (CoordinateManager.glass.attr("width") / 2);
    var ny = vpcy + (Math.sin(angle + current_angle) * d) - (CoordinateManager.glass.attr("height") / 2);

    CoordinateManager.glass.attr("x", nx);
    CoordinateManager.glass.attr("y", ny);
                    
    CoordinateManager.glass.rotate(degrees);
    
    CoordinateManager.glass.rotation = degrees;

    if (CropManager.selectedCrop !== null)
        CropManager.selectedCrop.setResizable(false);

    TileManager.updatePosition();
    CropManager.updatePosition();
    ControlManager.updateRotation(degrees);
    ControlManager.toFront();
};

/**
 * Fetch the current zoom level/coefficient.
 */
 
CoordinateManager.zoomCoefficient = function()
{
    return Math.pow(2, this.level_count - this.current_level);
};

/**
 * Get the coefficient for a given zoom level.
 */
 
CoordinateManager.zoomCoefficientForLevel = function(level)
{
    return Math.pow(2, this.level_count - level);
};

/**
 * Set the zoom level based on the mouse event. Regular click = zoom in, right-click = zoom out.
 */
 
CoordinateManager.mouseZoom = function(event, delta)
{
    var now = new Date();
    
    if (CoordinateManager.lastMouseZoom !== undefined && now.getTime() - CoordinateManager.lastMouseZoom.getTime() < 500)
        return;
                
    CoordinateManager.lastMouseZoom = now;
            
    var shift_click = false;

    if (delta < 0)
        shift_click = true;

    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;
    
    var click_x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var click_y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    var new_level = CoordinateManager.current_level + 1;
            
    if (shift_click)
    {
        new_level = CoordinateManager.current_level - 1;
    }
            
    if (new_level > CoordinateManager.level_count || new_level < CoordinateManager.base_level)
    {
        new_level = CoordinateManager.current_level;
    }
    else if (shift_click)
    {
        click_x = click_x / 2;
        click_y = click_y / 2;
    }
    else
    {
        click_x = click_x * 2;
        click_y = click_y * 2;
    }

    CoordinateManager.setViewport(click_x, click_y, new_level);
};

/**
 * Sets the drawable area's viewport. Works with other elements (ControlManager, TileManager, etc.) 
 *     to reflect the proper viewport.
 */
 
CoordinateManager.setViewport = function(cx, cy, level)
{
    var ratio_level = (level - CoordinateManager.base_level) / (CoordinateManager.level_count - 
                       CoordinateManager.base_level);

    if (CoordinateManager.glass === undefined)
    {
        CoordinateManager.glass = CropTool.paper.rect(10, 10,  10, 10);
        CoordinateManager.glass.rotation = 0;
        CoordinateManager.glass.loadedTiles = {};
            
        var start = function () 
        {
            this.ox = this.attr("x");
            this.oy = this.attr("y");

            TileManager.updatePosition();
            CropManager.updatePosition();       
            ControlManager.toFront();
        };
    
        var move = function (dx, dy) 
        {   
            this.rotate(0 - this.rotation);
        
            this.attr({x: this.ox + dx, y: this.oy + dy});
    
            this.rotate(this.rotation);

            TileManager.updatePosition();       
            CropManager.updatePosition();       
            ControlManager.toFront();
        };
        
        var up = function () 
        {
            CoordinateManager.setViewport((CoordinateManager.viewport_width / 2) - 
                                          CoordinateManager.glass.attr("x"), 
                                          (CoordinateManager.viewport_height / 2) - 
                                          CoordinateManager.glass.attr("y"),
                                          CoordinateManager.current_level);
            ControlManager.toFront();
        };

        CoordinateManager.glass.dblclick(function(evt)
        {
            var shift_click = evt.shiftKey;
            
            var pos = $(CropTool.rootDiv).offset();

            var click_x = evt.clientX - 10 - CoordinateManager.glass.attr("x") - pos.left;
            var click_y = evt.clientY - 10 - CoordinateManager.glass.attr("y") - pos.top;

            var new_level = CoordinateManager.current_level + 1;
            
            if (shift_click)
            {
                new_level = CoordinateManager.current_level - 1;
            }
            
            if (new_level > CoordinateManager.level_count || new_level < 
                CoordinateManager.base_level)
            {
                new_level = CoordinateManager.current_level;
            }
            else if (shift_click)
            {
                click_x = click_x / 2;
                click_y = click_y / 2;
            }
            else
            {
                click_x = click_x * 2;
                click_y = click_y * 2;
            }

            CoordinateManager.setViewport(click_x, click_y, new_level);
        });
        
        $(CoordinateManager.glass.node).bind('mousewheel', CoordinateManager.mouseZoom);

        CoordinateManager.glass.drag(move, start, up);

        CoordinateManager.glass.attr("fill", "#f00");
        CoordinateManager.glass.attr("opacity", "0.0");
//        CoordinateManager.glass.attr("opacity", "0.5");
    }

    CoordinateManager.glass.rotate(0 - CoordinateManager.glass.rotation);
    
    if (level !== CoordinateManager.current_level)
    {
        CoordinateManager.glass.loadedTiles = {};

        TileManager.reset();
    }
    
    CoordinateManager.current_level = level;
    
    var width = ImageServer.details.width / CoordinateManager.zoomCoefficientForLevel(level);
    var height = ImageServer.details.height / CoordinateManager.zoomCoefficientForLevel(level);

    var x = (CoordinateManager.viewport_width / 2) - cx;
    var y = (CoordinateManager.viewport_height / 2) - cy;

//	alert(ImageServer.details.width + " xx  " + ImageServer.details.height);

    CoordinateManager.glass.o_width = width;
    CoordinateManager.glass.o_height = height;

	width = Math.ceil(width / ImageServer.tile_size) * ImageServer.tile_size;
	height = Math.ceil(height / ImageServer.tile_size) * ImageServer.tile_size;

    CoordinateManager.glass.attr("x", x);
    CoordinateManager.glass.attr("y", y);
    CoordinateManager.glass.attr("width", width);
    CoordinateManager.glass.attr("height", height);

    CoordinateManager.glass.toFront();

    var dx = cx - (CoordinateManager.glass.attr("width") / 2); 
    var dy = cy - (CoordinateManager.glass.attr("height") / 2); 

    var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

    var angle = Math.atan2(dy, dx);
    
    dx = d * Math.cos(angle - (CoordinateManager.glass.rotation * (Math.PI / 180)));
    dy = d * Math.sin(angle - (CoordinateManager.glass.rotation * (Math.PI / 180)));

    cx = (CoordinateManager.glass.attr("width") / 2) + dx;
    cy = (CoordinateManager.glass.attr("height") / 2) + dy;

    CoordinateManager.glass.rotate(CoordinateManager.glass.rotation);

    var side = Math.sqrt(Math.pow(CoordinateManager.viewport_width / 2, 2), 
                         Math.pow(CoordinateManager.viewport_height / 2, 2));

    var left = cx - side;
    var top = cy - side;
    
    var x_offset = Math.floor(left / ImageServer.tile_size);
    var y_offset = Math.floor(top / ImageServer.tile_size);
    
//    TileManager.clearTileQueue();

    for (var i = -1; (i * ImageServer.tile_size) < (2 * side) + ImageServer.tile_size; i++)
    {
        for (var j = -1; (j * ImageServer.tile_size) < (2 * side) + ImageServer.tile_size; j++)
        {
            var i_index = x_offset + i;
            var j_index = y_offset + j;
            
            TileManager.loadTile(i_index, j_index, level);
        }
    }

    TileManager.updatePosition();       
    CropManager.updatePosition();
    ControlManager.viewportUpdated(cx, cy, level);
};

CoordinateManager.setZoomRatio = function(ratio)
{
    var levels = CoordinateManager.level_count - CoordinateManager.base_level;
    
    var offset = Math.round(levels * ratio);

    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;
    
    var x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    var dest_level = CoordinateManager.base_level + offset;
    
    if (CoordinateManager.base_level + offset > CoordinateManager.current_level)
    {
        while (CoordinateManager.base_level + offset > CoordinateManager.current_level)
        {
            x = x * 2;
            y = y * 2;
        
            offset -= 1;
        }
    }
    else if (CoordinateManager.base_level + offset < CoordinateManager.current_level)
    {
        while (CoordinateManager.base_level + offset < CoordinateManager.current_level)
        {
            x = x / 2;
            y = y / 2;

            offset += 1;
        }
    }

    CoordinateManager.setViewport(x, y, dest_level);
};

/**
 * Zooms in the viewport.
 */
 
CoordinateManager.zoomIn = function ()
{
    if (CoordinateManager.current_level >= CoordinateManager.level_count)
    {
        alert("Cannot zoom in further.");
        return;
    }
    
    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;

    var x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    CoordinateManager.setViewport((x * 2), (y * 2), CoordinateManager.current_level + 1);
};

/**
 * Zoom out the viewport.
 */

CoordinateManager.zoomOut = function ()
{
    if (CoordinateManager.current_level <= CoordinateManager.base_level)
    {
        alert("Cannot zoom out further.");
        return;
    }
        
    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;

    var x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    CoordinateManager.setViewport((x / 2), (y / 2), CoordinateManager.current_level - 1);
};
/*global $, PersistenceManager, TileManager, CropTool, ImageServer, ControlManager, 
	CoordinateManager, MetadataManager */

/**
 * @fileoverview This file contains the code that manages the display and positioning of crops on 
 *	   the drawable surface.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */


var CropManager = {};

CropManager.editable = false;
CropManager.drawable = false;
CropManager.draw_canvas = null;

CropManager.crops = [];
CropManager.selectedCrop = null;

/**
 * Highlights the selected crop & displays the resize controls when rotation = 0.
 */
 
CropManager.selectCrop = function(crop)
{
	if (CropManager.selectedCrop === crop)
	{
		return;
	}
	
	if (crop !== null)
	{
		if (CropManager.selectedCrop !== null)
		{
			CropManager.selectedCrop.rect.attr("fill-opacity", "0.1");
			CropManager.selectedCrop.setResizable(false);
		}

		CropManager.selectedCrop = crop;
		
		if (crop.rect !== null)
		{
			crop.rect.attr("fill-opacity", "0.5");
		}
	
		if (CropTool.editable && (CropManager.selectedCrop.rotation + CoordinateManager.glass.rotation) === 0)
		{
			CropManager.selectedCrop.setResizable(true);
		}

		MetadataManager.showCropDetails(CropManager.selectedCrop);
	}
	else
	{
		CropManager.selectedCrop.rect.attr("fill-opacity", "0.1");
		CropManager.selectedCrop.setResizable(false);

		CropManager.selectedCrop = null;

		MetadataManager.hideCropDetails();
	}
};

CropManager.createNewCrop = function()
{
	var crop = {};
	crop.uuid = uuid();
			
	crop.flagDirty = function()
	{
		this.dirty = true;
				
		if (MetadataManager !== undefined)
		{
			MetadataManager.showDirtyCrop(this);
		}
	};
	
	crop.setViewPort = function()
	{
		var win_width = $(CropTool.rootDiv).width() - 20;
		var win_height = $(CropTool.rootDiv).height() - 20;

		var side = win_width;
		if (win_height < win_width)
		{
			side = win_height;
		}
		
		var x = this.cx * CoordinateManager.glass.o_width;
		var y = this.cy * CoordinateManager.glass.o_height;
			
		var level = CoordinateManager.base_level;
		var zce = CoordinateManager.zoomCoefficientForLevel(level);

		while (((this.width * ImageServer.details.width) / zce) < side && 
			   ((this.height * ImageServer.details.height) / zce) < side)
		{
			level += 1;
			zce = CoordinateManager.zoomCoefficientForLevel(level);
		}

		//level = level - 1;
		zce = CoordinateManager.zoomCoefficientForLevel(level);
				
		x = (this.cx * ImageServer.details.width) / zce;
		y = (this.cy * ImageServer.details.height) / zce;

		CoordinateManager.setRotation(0);
		CoordinateManager.setViewport(x, y, level);
		CoordinateManager.setRotation(0 - this.rotation);
				
		CropManager.setEditable(true);

		if (CropTool.editable)
		{
		   this.setResizable(true);
		}
	};
	
	crop.metadata = {};
	
	return crop;
};


/**
 * Updates the display and position of the crops when the viewport changes.
 */
 
CropManager.updatePosition = function()
{
	// Glass is the invisible layer on top of everything that responds to click & drag events.
	
	var glass = CoordinateManager.glass;
	
	if (glass === undefined)
	{
		return;
	}
	
	var cx = glass.attr("x") + (glass.o_width / 2);
	var cy = glass.attr("y") + (glass.o_height / 2);

	var glass_origin_x = cx - (glass.o_width / 2);
	var glass_origin_y = cy - (glass.o_height / 2);

	CoordinateManager.glass.toFront();

	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		// Remove the displayed rectangle.
		
		if (crop.rect !== undefined)
		{
			if (crop.drag_rect !== null)
			{
				crop.drag_rect.remove();
			}

			crop.rect.remove();
		}

		if (crop.drag_rect === undefined)
		{
			crop.drag_rect = null;
		}
		
		if (crop.setResizable === undefined)
		{
			// Setup the function that displays the resize controls & responds to resize events...
			
			crop.setResizable = function(is_resizable)
			{
				if (is_resizable === false && this.drag_rect !== null)
				{
					this.drag_rect.crop = null;
					this.drag_rect.remove();
					this.drag_rect = null;
				}
				else if (is_resizable && this.drag_rect === null)
				{
					this.drag_rect = CropTool.paper.rect(this.rect.attr("x") + this.rect.attr("width") - 4, this.rect.attr("y") + this.rect.attr("height") - 4, 8, 8);

					this.drag_rect.attr("stroke", "#000");
					this.drag_rect.attr("fill", "#fff");		
					this.drag_rect.attr("opacity", "1.0");
					this.drag_rect.crop = this;
					
					var s = function () 
					{
						this.o_x = this.attr("x");
						this.o_y = this.attr("y");

						this.rect_o_x = this.crop.rect.attr("x");
						this.rect_o_y = this.crop.rect.attr("y");
						this.rect_o_width = this.crop.rect.attr("width");
						this.rect_o_height = this.crop.rect.attr("height");
					};
	
					var m = function (dx, dy) 
					{
						this.attr("x", this.o_x + dx);
						this.attr("y", this.o_y + dy);
						
						var rect_x = this.rect_o_x;
						var rect_y = this.rect_o_y;

						var rect_width = this.attr("x") + (this.attr("width") / 2) - rect_x;
						var rect_height = this.attr("y") + (this.attr("height") / 2)  - rect_y;

						if (rect_width < 0)
						{
							rect_x = rect_x + rect_width;
						}
						
						if (rect_height < 0)
						{
							rect_y = rect_y + rect_height;
						}
						
						this.crop.rect.attr("x",  rect_x);
						this.crop.rect.attr("y",  rect_y);
						this.crop.rect.attr("width",  Math.abs(rect_width));
						this.crop.rect.attr("height", Math.abs(rect_height));
					};
		
					var u = function () 
					{
						var dx = this.crop.rect.attr("x") + (this.crop.rect.attr("width") / 2) - this.rect_o_x - (this.rect_o_width / 2);
						var dy = this.crop.rect.attr("y") + (this.crop.rect.attr("height") / 2) - this.rect_o_y - (this.rect_o_height / 2);
				
						var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
				
						var angle = Math.atan2(dy, dx) - (CoordinateManager.glass.rotation * (Math.PI / 180));
				
						this.crop.cx += ((d * Math.cos(angle)) / CoordinateManager.glass.o_width);
						this.crop.cy += ((d * Math.sin(angle)) / CoordinateManager.glass.o_height);
			
						this.crop.flagDirty();

						this.crop.width = this.crop.rect.attr("width") / CoordinateManager.glass.o_width;
						this.crop.height = this.crop.rect.attr("height") /	CoordinateManager.glass.o_height;
					};
				
					this.drag_rect.drag(m, s, u);
					this.drag_rect.toFront();
				}
			};
		}

		var x = glass_origin_x + (glass.o_width * crop.cx);
		var y = glass_origin_y + (glass.o_height * crop.cy);

		var width = glass.o_width * crop.width;
		var height = glass.o_height * crop.height;

		var angle = Math.atan2(y - cy, x - cx);
		var d = Math.sqrt(Math.pow(x - cx, 2) + Math.pow(y - cy, 2));

		var real_x = d * Math.cos((glass.rotation * Math.PI / 180) + angle);
		var real_y = d * Math.sin((glass.rotation * Math.PI / 180) + angle);

		// Draw the colored rectangle that visually represents the crop...
		crop.rect = CropTool.paper.rect(cx + real_x - (width / 2), cy + real_y - (height / 2), width, height);
		crop.rect.crop = crop;
		
		$(crop.rect.node).bind('mousewheel', CoordinateManager.mouseZoom);

		crop.rect.rotate(glass.rotation + crop.rotation);
		crop.rect.attr("stroke", crop.color);
		crop.rect.attr("fill", "none");		

		// Setup the various mouse actions (click to select, double-click to edit, drag to move, 
		// etc...
		
		crop.rect.click(function(event)
		{
			CropManager.selectCrop(this.crop);
		});

		crop.rect.mouseover(function (event)
		{
			$("body").css("cursor", "pointer");
		});

		crop.rect.mouseout(function (event)
		{
			$("body").css("cursor", "default");
		});
			
		crop.rect.dblclick(function(event)
		{
			var dx = this.attr("x") - this.o_x;
			var dy = this.attr("y") - this.o_y;

			if (Math.abs(dx) + Math.abs(dy) < 20)
			{
				crop.setViewPort();
			}
		});
		
		var start = function() 
		{
			CropManager.selectCrop(this.crop);
			
			this.o_x = Math.floor(this.attr("x"));
			this.o_y = Math.floor(this.attr("y"));
		};
	
		var move = function(dx, dy) 
		{
			if (CropTool.editable)
			{
				this.attr("x", this.o_x + Math.floor(dx));
				this.attr("y", this.o_y + Math.floor(dy));

				if (this.crop.drag_rect !== null)
				{
					this.crop.drag_rect.attr("x", this.attr("x") + this.attr("width") - (this.crop.drag_rect.attr("width") / 2));
					this.crop.drag_rect.attr("y", this.attr("y") + this.attr("height") - (this.crop.drag_rect.attr("height") / 2));
				}
			}
		};
		
		var up = function() 
		{
			if (CropTool.editable)
			{
				var dx = this.attr("x") - this.o_x;
				var dy = this.attr("y") - this.o_y;
				
				var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
				
				var angle = Math.atan2(dy, dx) - (CoordinateManager.glass.rotation * (Math.PI / 180));
				
				this.crop.cx += ((d * Math.cos(angle)) / CoordinateManager.glass.o_width);
				this.crop.cy += ((d * Math.sin(angle)) / CoordinateManager.glass.o_height);

				this.crop.flagDirty();
			}
		};
		
		crop.rect.drag(move, start, up);
		
		crop.rect.toFront();
		
		if (crop.drag_rect !== null)
		{
			crop.drag_rect.toFront();
		}
	}

	// Update the mode...
	
	CropManager.setEditable(CropManager.editable);
	
	// Bring the glass to the front if crops are not editable (at the moment)...
	
	if (!CropManager.editable)
	{
		CoordinateManager.glass.toFront();
		ControlManager.toFront();
	}
	
	if (CropManager.draw_canvas !== null)
	{
		var dcx = glass.attr("x") + (glass.attr("width") / 2);
		var dcy = glass.attr("y") + (glass.attr("height") / 2);

		CropManager.draw_canvas.rotate(0, true);
		
		CropManager.draw_canvas.attr("x", dcx - (glass.o_width / 2));
		CropManager.draw_canvas.attr("y", dcy - (glass.o_height / 2));
	
		CropManager.draw_canvas.rotate(glass.rotation, true);
		CropManager.draw_canvas.toFront();
	}
	
	ControlManager.toFront();
};

/**
 * Bring the drawable elements to the front of the view stack.
 */
 
CropManager.toFront = function()
{
	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		if (crop.rect !== undefined)
		{
			crop.rect.toFront();
		}
		
		if (crop.drag_rect !== undefined && crop.drag_rect !== null)
		{
			crop.drag_rect.toFront();
		}
	}
};

/**
 * Bring the selected crop to the front for editing...
 */
 
CropManager.bringToFront = function(crop_id)
{
	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		if (crop.uuid === crop_id)
		{
			if (crop.rect !== undefined)
			{
				crop.rect.toFront();
			}
		
			if (crop.drag_rect !== undefined && crop.drag_rect !== null)
			{
				crop.drag_rect.toFront();
			}
			
			CropManager.crops.splice(i, 1);
			CropManager.crops.push(crop);
		}
	}
};

/**
 * Setup the crop for editing.
 */
 
CropManager.setEditable = function(is_editable)
{
	CropManager.editable = is_editable;
		
	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		if (crop.rect !== undefined)
		{
			if (crop.setResizable !== undefined)
			{
				crop.setResizable(false);
			}
			
			if (is_editable)
			{
				crop.rect.attr("fill", crop.color);		
				crop.rect.attr("fill-opacity", "0.10");
	
				if (crop === CropManager.selectedCrop)
				{
					crop.rect.attr("fill-opacity", "0.5");

					if (CropTool.editable && crop.rotation + CoordinateManager.glass.rotation === 0)
					{
						CropManager.selectedCrop.setResizable(true);
					}

					if (crop.drag_rect !== null)
					{
						CropManager.selectedCrop.drag_rect.attr("x", CropManager.selectedCrop.rect.attr("x") + CropManager.selectedCrop.rect.attr("width") - (CropManager.selectedCrop.drag_rect.attr("width") / 2));
						CropManager.selectedCrop.drag_rect.attr("y", CropManager.selectedCrop.rect.attr("y") + CropManager.selectedCrop.rect.attr("height") - (CropManager.selectedCrop.drag_rect.attr("height") / 2));
					}
				}

				crop.rect.toFront();

				if (crop.drag_rect !== null)
				{
					crop.drag_rect.toFront();
				}
			}
			else
			{
				crop.rect.attr("fill", "none");		
			}
		}
	}
};

/**
 * Removes the selected crop from the display.
 */

CropManager.removeSelectedCrop = function()
{
	if (CropManager.selectedCrop !== null)
	{
		if (confirm("Clear selected region from image?"))
		{
			if (CropManager.selectedCrop.drag_rect !== null)
			{
				CropManager.selectedCrop.drag_rect.remove();
			}

			if (CropManager.selectedCrop.rect !== null)
			{
				CropManager.selectedCrop.rect.remove();
			}
			
			var index = -1;
		
			var i = 0;
			
			for (i = 0; i < CropManager.crops.length; i++)
			{
				if (CropManager.selectedCrop === CropManager.crops[i])
				{
					index = i;
				}
			}	
		
			if (index >= 0)
			{
				CropManager.crops.splice(index, 1);
			}
			
			CropManager.selectCrop(null);
			
			CropManager.updatePosition();
		}
	}
};

/**
 * Set the display layer to a "drawable" mode.
 */
 
CropManager.setDrawable = function(is_drawable)
{
	CropManager.drawable = is_drawable;
	
	if (CropManager.drawable)
	{
		var glass = CoordinateManager.glass;
		
		var cx = glass.attr("x") + (glass.attr("width") / 2);
		var cy = glass.attr("y") + (glass.attr("height") / 2);
		
		CropManager.draw_canvas = CropTool.paper.rect(cx - (glass.o_width / 2), cy - (glass.o_height / 2), glass.o_width, glass.o_height);
		CropManager.draw_canvas.attr("stroke", "#fff");
		CropManager.draw_canvas.attr("fill", "#fff");		
		CropManager.draw_canvas.attr("fill-opacity", "0.0");		

		CropManager.draw_canvas.rotate(glass.rotation);

		CropManager.draw_canvas.draw_rect = null;		

		// Draw crop methods...
		
		CropManager.draw_canvas.mousedown(function(event) 
		{
			CropManager.draw_canvas.start_x = event.clientX - 10;
			CropManager.draw_canvas.start_y = event.clientY - 10;
			
			CropManager.draw_canvas.draw_rect = CropTool.paper.rect(CropManager.draw_canvas.start_x, CropManager.draw_canvas.start_y, 1, 1);
			CropManager.draw_canvas.draw_rect.attr("stroke", crop.color);
		});

		var start = function () 
		{

		};
	
		var move = function (dx, dy) 
		{
			if (CropManager.draw_canvas.draw_rect !== null)
			{
				CropManager.draw_canvas.draw_rect.attr("width", Math.abs(dx));
				CropManager.draw_canvas.draw_rect.attr("height", Math.abs(dy));
				
				if (dx < 0)
				{
					CropManager.draw_canvas.draw_rect.attr("x", CropManager.draw_canvas.start_x + dx);
				}
				else					
				{
					CropManager.draw_canvas.draw_rect.attr("x", CropManager.draw_canvas.start_x);
				}

				if (dy < 0)
				{
					CropManager.draw_canvas.draw_rect.attr("y", CropManager.draw_canvas.start_y + dy);
				}
				else					
				{
					CropManager.draw_canvas.draw_rect.attr("y", CropManager.draw_canvas.start_y);
				}
			}
		};
		
		var up = function () 
		{
			if (CropManager.draw_canvas.draw_rect !== null)
			{
				var crop = {};
				crop.color = "#ff0000";

				crop.metadata = {};
				
				var fields = PersistenceManager.getFields();
				
				var i = 0;
				
				for (i = 0; i < fields.length; i++)
				{
					var field = fields[i];
					
					crop.metadata[field.field] = field.value;
				}
			
				var canvas_width = CropManager.draw_canvas.attr("width");
				var canvas_height = CropManager.draw_canvas.attr("height");

				var canvas_cx = CropManager.draw_canvas.attr("x") + (canvas_width / 2);
				var canvas_cy = CropManager.draw_canvas.attr("y") + (canvas_height / 2);
				
				var width = CropManager.draw_canvas.draw_rect.attr("width");
				var height = CropManager.draw_canvas.draw_rect.attr("height");
				
				var rect_cx = CropManager.draw_canvas.draw_rect.attr("x") + (width / 2);
				var rect_cy = CropManager.draw_canvas.draw_rect.attr("y") + (height / 2);
				
				var delta_x = rect_cx - canvas_cx;
				var delta_y = rect_cy - canvas_cy;
				
				var d = Math.sqrt(Math.pow(delta_x, 2) + Math.pow(delta_y, 2));
				var angle = Math.atan2(delta_y, delta_x) - (CoordinateManager.glass.rotation * (Math.PI / 180));

				var cx = (((d * Math.cos(angle)) + canvas_cx) - CropManager.draw_canvas.attr("x")) / canvas_width;
				var cy = (((d * Math.sin(angle)) + canvas_cy) - CropManager.draw_canvas.attr("y")) / canvas_height;
				
				crop.cx = cx;
				crop.cy = cy;
				crop.uuid = uuid();
				
				crop.width = width / canvas_width;
				crop.height = height / canvas_height;

				crop.rotation = 0 - CoordinateManager.glass.rotation;

				CropManager.crops.push(crop);
				
				MetadataManager.refresh();
			
				CropManager.draw_canvas.draw_rect.remove();
				
				CropManager.draw_canvas.draw_rect = null;
				
				CropManager.editable = true;

				CropManager.updatePosition();				
				
				ControlManager.setMode("edit");

				CropManager.selectCrop(crop);
			}
			
			CropManager.setDrawable(false);
			
			CropManager.updatePosition();
		};

		CropManager.draw_canvas.drag(move, start, up);

		CropManager.draw_canvas.toFront();
	}
	else
	{
		if (CropManager.draw_canvas !== null)
		{
			CropManager.draw_canvas.remove();
		
			CropManager.draw_canvas = null;
		}
	}

	ControlManager.toFront();
};

/*global $, document, window, Raphael, ImageServer, ControlManager */

/**
 * @fileoverview This file contains the code that initializes Crop Tool and sets up the drawing area
 *     within the current browser window. It includes the functionality that resizes the drawing 
 *     area on browser window resizes.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */

 
var CropTool = {};

CropTool.paper = null;
CropTool.editable = false;
CropTool.isCrop = false;

CropTool.initialize = function(identifier, editable, rootDiv, isCrop)
{
	CropTool.editable = editable;
	CropTool.rootDiv = rootDiv.get(0);
	CropTool.isCrop = isCrop;
	
	// Establish a drawing area with a 10px border from the edges of the browser frame.
	
    var width = $(CropTool.rootDiv).width();
    var height = $(CropTool.rootDiv).height();

	// CropTool.paper is the main area in which all drawing and image placement will happen. This 
	//     is the base "canvas".
	
	var pos = $(CropTool.rootDiv).offset();

    CropTool.paper = Raphael(CropTool.rootDiv, width, height);
    
    // TODO: Remove this...

    CropTool.resize = function ()
    {
        var width = $(CropTool.rootDiv).width();
        var height = $(CropTool.rootDiv).height();

		var pos = $(CropTool.rootDiv).offset();
    
        CropTool.paper.setSize(width, height);

//		$("svg").css("left", (pos.left + 1) + "px");
//		$("svg").css("top", (pos.top + 1) + "px");

//	    $("svg").css("position", "relative");

		ControlManager.resize(width, height);	
		ControlManager.toFront();
    };
    
    $(window).resize(CropTool.resize);

//    $("body").css("overflow", "hidden");

	// Round the corners of the metadata panels. These are setup within another file:
	//     metadata-manager.js

    $("div#metadata").corner("5px");
    $("div#crop-metadata").corner("3px");

	CropTool.identifier = identifier;

	ImageServer.initialize(identifier);
};
function uuid() 
{
    // http://www.ietf.org/rfc/rfc4122.txt
    // http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
    
    var s = [];
    var hexDigits = "0123456789ABCDEF";
    for (var i = 0; i < 32; i++) {
        s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
    }
    s[12] = "4";  // bits 12-15 of the time_hi_and_version field to 0010
    s[16] = hexDigits.substr((s[16] & 0x3) | 0x8, 1);  // bits 6-7 of the clock_seq_hi_and_reserved to 01

    var uuid = s.join("");
    return uuid;
}

function parseXml (string)
{
	var browserName = navigator.appName;
	var doc;
	if (browserName == 'Microsoft Internet Explorer')
	{
		doc = new ActiveXObject('Microsoft.XMLDOM');
		doc.async = 'false'
		doc.loadXML(string);
	} 
	else 
	{
		doc = (new DOMParser()).parseFromString(string, 'text/xml');
	}
	
	return doc;
}

function serializeXml(node)
{
	if (typeof XMLSerializer != "undefined")
		return (new XMLSerializer()).serializeToString(node);
	else if (node.xml)
		return node.xml;
	else
		return "???";
}
;
/**
 *
 * Zoomimage
 * Author: Stefan Petre www.eyecon.ro
 * 
 */

(function($){
	var EYE = window.EYE = function() {
		var _registered = {
			init: []
		};
		return {
			init: function() {
				$.each(_registered.init, function(nr, fn){
					fn.call();
				});
			},
			extend: function(prop) {
				for (var i in prop) {
					if (prop[i] != undefined) {
						this[i] = prop[i];
					}
				}
			},
			register: function(fn, type) {
				if (!_registered[type]) {
					_registered[type] = [];
				}
				_registered[type].push(fn);
			}
		};
	}();
	$(EYE.init);
})(jQuery);
// (function($){$.jQTouch=function(_2){$.support.WebKitCSSMatrix=(typeof WebKitCSSMatrix=="object");$.support.touch=(typeof Touch=="object");$.support.WebKitAnimationEvent=(typeof WebKitTransitionEvent=="object");var _3,$head=$("head"),hist=[],newPageCount=0,jQTSettings={},hashCheck,currentPage,orientation,isMobileWebKit=RegExp(" Mobile/").test(navigator.userAgent),tapReady=true,lastAnimationTime=0,touchSelectors=[],publicObj={},extensions=$.jQTouch.prototype.extensions,defaultAnimations=["slide","flip","slideup","swap","cube","pop","dissolve","fade","back"],animations=[],hairextensions="";init(_2);function init(_4){var _5={addGlossToIcon:true,backSelector:".back, .cancel, .goback",cacheGetRequests:true,cubeSelector:".cube",dissolveSelector:".dissolve",fadeSelector:".fade",fixedViewport:true,flipSelector:".flip",formSelector:"form",fullScreen:true,fullScreenClass:"fullscreen",icon:null,touchSelector:"a, .touch",popSelector:".pop",preloadImages:false,slideSelector:"body > * > ul li a",slideupSelector:".slideup",startupScreen:null,statusBar:"default",submitSelector:".submit",swapSelector:".swap",useAnimations:true,useFastTouch:true};jQTSettings=$.extend({},_5,_4);if(jQTSettings.preloadImages){for(var i=jQTSettings.preloadImages.length-1;i>=0;i--){(new Image()).src=jQTSettings.preloadImages[i];}}if(jQTSettings.icon){var _7=(jQTSettings.addGlossToIcon)?"":"-precomposed";hairextensions+="<link rel=\"apple-touch-icon"+_7+"\" href=\""+jQTSettings.icon+"\" />";}if(jQTSettings.startupScreen){hairextensions+="<link rel=\"apple-touch-startup-image\" href=\""+jQTSettings.startupScreen+"\" />";}if(jQTSettings.fixedViewport){hairextensions+="<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0;\"/>";}if(jQTSettings.fullScreen){hairextensions+="<meta name=\"apple-mobile-web-app-capable\" content=\"yes\" />";if(jQTSettings.statusBar){hairextensions+="<meta name=\"apple-mobile-web-app-status-bar-style\" content=\""+jQTSettings.statusBar+"\" />";}}if(hairextensions){$head.append(hairextensions);}$(document).ready(function(){for(var i in extensions){var fn=extensions[i];if($.isFunction(fn)){$.extend(publicObj,fn(publicObj));}}for(var i in defaultAnimations){var _a=defaultAnimations[i];var _b=jQTSettings[_a+"Selector"];if(typeof (_b)=="string"){addAnimation({name:_a,selector:_b});}}touchSelectors.push("input");touchSelectors.push(jQTSettings.touchSelector);touchSelectors.push(jQTSettings.backSelector);touchSelectors.push(jQTSettings.submitSelector);$(touchSelectors.join(", ")).css("-webkit-touch-callout","none");$(jQTSettings.backSelector).tap(liveTap);$(jQTSettings.submitSelector).tap(submitParentForm);_3=$("body");if(jQTSettings.fullScreenClass&&window.navigator.standalone==true){_3.addClass(jQTSettings.fullScreenClass+" "+jQTSettings.statusBar);}_3.bind("touchstart",handleTouch).bind("orientationchange",updateOrientation).trigger("orientationchange").submit(submitForm);if(jQTSettings.useFastTouch&&$.support.touch){_3.click(function(e){var _d=$(e.target);if(_d.attr("target")=="_blank"||_d.attr("rel")=="external"||_d.is("input[type=\"checkbox\"]")){return true;}else{return false;}});_3.mousedown(function(e){var _f=(new Date()).getTime()-lastAnimationTime;if(_f<200){return false;}});}if($("body > .current").length==0){currentPage=$("body > *:first");}else{currentPage=$("body > .current:first");$("body > .current").removeClass("current");}$(currentPage).addClass("current");location.hash=$(currentPage).attr("id");addPageToHistory(currentPage);scrollTo(0,0);dumbLoopStart();});}function goBack(to){if(hist.length>1){var _11=Math.min(parseInt(to||1,10),hist.length-1);if(isNaN(_11)&&typeof (to)==="string"&&to!="#"){for(var i=1,length=hist.length;i<length;i++){if("#"+hist[i].id===to){_11=i;break;}}}if(isNaN(_11)||_11<1){_11=1;}var _13=hist[0].animation;var _14=hist[0].page;hist.splice(0,_11);var _15=hist[0].page;animatePages(_14,_15,_13,true);return publicObj;}else{console.error("No pages in history.");return false;}}function goTo(_16,_17){var _18=hist[0].page;if(typeof (_16)==="string"){_16=$(_16);}if(typeof (_17)==="string"){for(var i=animations.length-1;i>=0;i--){if(animations[i].name===_17){_17=animations[i];break;}}}if(animatePages(_18,_16,_17)){addPageToHistory(_16,_17);return publicObj;}else{console.error("Could not animate pages.");return false;}}function getOrientation(){return orientation;}function liveTap(e){var $el=$(e.target);if($el.attr("nodeName")!=="A"){$el=$el.parent("a");}var _1c=$el.attr("target"),hash=$el.attr("hash"),animation=null;if(tapReady==false||!$el.length){console.warn("Not able to tap element.");return false;}if($el.attr("target")=="_blank"||$el.attr("rel")=="external"){return true;}for(var i=animations.length-1;i>=0;i--){if($el.is(animations[i].selector)){animation=animations[i];break;}}if(_1c=="_webapp"){window.location=$el.attr("href");}else{if($el.is(jQTSettings.backSelector)){goBack(hash);}else{if(hash&&hash!="#"){$el.addClass("active");goTo($(hash).data("referrer",$el),animation);}else{$el.addClass("loading active");showPageByHref($el.attr("href"),{animation:animation,callback:function(){$el.removeClass("loading");setTimeout($.fn.unselect,250,$el);},$referrer:$el});}}}return false;}function addPageToHistory(_1e,_1f){var _20=_1e.attr("id");hist.unshift({page:_1e,animation:_1f,id:_20});}function animatePages(_21,_22,_23,_24){if(_22.length===0){$.fn.unselect();console.error("Target element is missing.");return false;}$(":focus").blur();scrollTo(0,0);var _25=function(_26){if(_23){_22.removeClass("in reverse "+_23.name);_21.removeClass("current out reverse "+_23.name);}else{_21.removeClass("current");}_22.trigger("pageAnimationEnd",{direction:"in"});_21.trigger("pageAnimationEnd",{direction:"out"});clearInterval(dumbLoop);currentPage=_22;location.hash=currentPage.attr("id");dumbLoopStart();var _27=_22.data("referrer");if(_27){_27.unselect();}lastAnimationTime=(new Date()).getTime();tapReady=true;};_21.trigger("pageAnimationStart",{direction:"out"});_22.trigger("pageAnimationStart",{direction:"in"});if($.support.WebKitAnimationEvent&&_23&&jQTSettings.useAnimations){_22.one("webkitAnimationEnd",_25);tapReady=false;_22.addClass(_23.name+" in current "+(_24?" reverse":""));_21.addClass(_23.name+" out"+(_24?" reverse":""));}else{_22.addClass("current");_25();}return true;}function dumbLoopStart(){dumbLoop=setInterval(function(){var _28=currentPage.attr("id");if(location.hash==""){location.hash="#"+_28;}else{if(location.hash!="#"+_28){try{goBack(location.hash);}catch(e){console.error("Unknown hash change.");}}}},100);}function insertPages(_29,_2a){var _2b=null;$(_29).each(function(_2c,_2d){var _2e=$(this);if(!_2e.attr("id")){_2e.attr("id","page-"+(++newPageCount));}_2e.appendTo(_3);if(_2e.hasClass("current")||!_2b){_2b=_2e;}});if(_2b!==null){goTo(_2b,_2a);return _2b;}else{return false;}}function showPageByHref(_2f,_30){var _31={data:null,method:"GET",animation:null,callback:null,$referrer:null};var _32=$.extend({},_31,_30);if(_2f!="#"){$.ajax({url:_2f,data:_32.data,type:_32.method,success:function(_33,_34){var _35=insertPages(_33,_32.animation);if(_35){if(_32.method=="GET"&&jQTSettings.cacheGetRequests&&_32.$referrer){_32.$referrer.attr("href","#"+_35.attr("id"));}if(_32.callback){_32.callback(true);}}},error:function(_36){if(_32.$referrer){_32.$referrer.unselect();}if(_32.callback){_32.callback(false);}}});}else{if($referrer){$referrer.unselect();}}}function submitForm(e,_38){var _39=(typeof (e)==="string")?$(e):$(e.target);if(_39.length&&_39.is(jQTSettings.formSelector)&&_39.attr("action")){showPageByHref(_39.attr("action"),{data:_39.serialize(),method:_39.attr("method")||"POST",animation:animations[0]||null,callback:_38});return false;}return true;}function submitParentForm(e){var _3b=$(this).closest("form");if(_3b.length){evt=jQuery.Event("submit");evt.preventDefault();_3b.trigger(evt);return false;}return true;}function addAnimation(_3c){if(typeof (_3c.selector)=="string"&&typeof (_3c.name)=="string"){animations.push(_3c);$(_3c.selector).tap(liveTap);touchSelectors.push(_3c.selector);}}function updateOrientation(){orientation=window.innerWidth<window.innerHeight?"profile":"landscape";_3.removeClass("profile landscape").addClass(orientation).trigger("turn",{orientation:orientation});}function handleTouch(e){var $el=$(e.target);if(!$(e.target).is(touchSelectors.join(", "))){var _3f=$(e.target).closest("a");if(_3f.length){$el=_3f;}else{return;}}if(event){var _40=null,startX=event.changedTouches[0].clientX,startY=event.changedTouches[0].clientY,startTime=(new Date).getTime(),deltaX=0,deltaY=0,deltaT=0;$el.bind("touchmove",touchmove).bind("touchend",touchend);_40=setTimeout(function(){$el.makeActive();},100);}function touchmove(e){updateChanges();var _42=Math.abs(deltaX);var _43=Math.abs(deltaY);if(_42>_43&&(_42>35)&&deltaT<1000){$el.trigger("swipe",{direction:(deltaX<0)?"left":"right"}).unbind("touchmove touchend");}else{if(_43>1){$el.removeClass("active");}}clearTimeout(_40);}function touchend(){updateChanges();if(deltaY===0&&deltaX===0){$el.makeActive();$el.trigger("tap");}else{$el.removeClass("active");}$el.unbind("touchmove touchend");clearTimeout(_40);}function updateChanges(){var _44=event.changedTouches[0]||null;deltaX=_44.pageX-startX;deltaY=_44.pageY-startY;deltaT=(new Date).getTime()-startTime;}}$.fn.unselect=function(obj){if(obj){obj.removeClass("active");}else{$(".active").removeClass("active");}};$.fn.makeActive=function(){return $(this).addClass("active");};$.fn.swipe=function(fn){if($.isFunction(fn)){return this.each(function(i,el){$(el).bind("swipe",fn);});}};$.fn.tap=function(fn){if($.isFunction(fn)){var _4a=(jQTSettings.useFastTouch&&$.support.touch)?"tap":"click";return $(this).live(_4a,fn);}else{$(this).trigger("tap");}};publicObj={getOrientation:getOrientation,goBack:goBack,goTo:goTo,addAnimation:addAnimation,submitForm:submitForm};return publicObj;};$.jQTouch.prototype.extensions=[];$.jQTouch.addExtension=function(_4b){$.jQTouch.prototype.extensions.push(_4b);};})(jQuery);
// /*

//             _/    _/_/    _/_/_/_/_/                              _/
//                _/    _/      _/      _/_/    _/    _/    _/_/_/  _/_/_/
//           _/  _/  _/_/      _/    _/    _/  _/    _/  _/        _/    _/
//          _/  _/    _/      _/    _/    _/  _/    _/  _/        _/    _/
//         _/    _/_/  _/    _/      _/_/      _/_/_/    _/_/_/  _/    _/
//        _/
//     _/

//     Created by David Kaneda <http://www.davidkaneda.com>
//     Documentation and issue tracking on Google Code <http://code.google.com/p/jqtouch/>

//     Special thanks to Jonathan Stark <http://jonathanstark.com/>
//     and pinch/zoom <http://www.pinchzoom.com/>

//     (c) 2009 by jQTouch project members.
//     See LICENSE.txt for license.

// */

// (function($) {

//     $.fn.transition = function(css, options) {
//         return this.each(function(){
//             var $el = $(this);
//             var defaults = {
//                 speed : '300ms',
//                 callback: null,
//                 ease: 'ease-in-out'
//             };
//             var settings = $.extend({}, defaults, options);
//             if(settings.speed === 0) {
//                 $el.css(css);
//                 window.setTimeout(settings.callback, 0);
//             } else {
//                 if ($.browser.safari)
//                 {
//                     var s = [];
//                     for(var i in css) {
//                         s.push(i);
//                     }
//                     $el.css({
//                         webkitTransitionProperty: s.join(", "),
//                         webkitTransitionDuration: settings.speed,
//                         webkitTransitionTimingFunction: settings.ease
//                     });
//                     if (settings.callback) {
//                         $el.one('webkitTransitionEnd', settings.callback);
//                     }
//                     setTimeout(function(el){ el.css(css) }, 0, $el);
//                 }
//                 else
//                 {
//                     $el.animate(css, settings.speed, settings.callback);
//                 }
//             }
//         });
//     }
// })(jQuery);
/*!
 * jQuery corner plugin: simple corner rounding
 * Examples and documentation at: http://jquery.malsup.com/corner/
 * version 2.13 (19-FEB-2013)
 * Requires jQuery v1.3.2 or later
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 * Authors: Dave Methvin and Mike Alsup
 */

/**
 *  corner() takes a single string argument:  $('#myDiv').corner("effect corners width")
 *
 *  effect:  name of the effect to apply, such as round, bevel, notch, bite, etc (default is round).
 *  corners: one or more of: top, bottom, tr, tl, br, or bl.  (default is all corners)
 *  width:   width of the effect; in the case of rounded corners this is the radius.
 *           specify this value using the px suffix such as 10px (yes, it must be pixels).
 */

;(function($) {

var msie = /MSIE/.test(navigator.userAgent);

var style = document.createElement('div').style,
    moz = style['MozBorderRadius'] !== undefined,
    webkit = style['WebkitBorderRadius'] !== undefined,
    radius = style['borderRadius'] !== undefined || style['BorderRadius'] !== undefined,
    mode = document.documentMode || 0,
    noBottomFold = msie && (!mode || mode < 8),

    expr = msie && (function() {
        var div = document.createElement('div');
        try { div.style.setExpression('width','0+0'); div.style.removeExpression('width'); }
        catch(e) { return false; }
        return true;
    })();

$.support = $.support || {};
$.support.borderRadius = moz || webkit || radius; // so you can do:  if (!$.support.borderRadius) $('#myDiv').corner();

function sz(el, p) {
    return parseInt($.css(el,p),10)||0;
}
function hex2(s) {
    s = parseInt(s,10).toString(16);
    return ( s.length < 2 ) ? '0'+s : s;
}
function gpc(node) {
    while(node) {
        var v = $.css(node,'backgroundColor'), rgb;
        if (v && v != 'transparent' && v != 'rgba(0, 0, 0, 0)') {
            if (v.indexOf('rgb') >= 0) {
                rgb = v.match(/\d+/g);
                return '#'+ hex2(rgb[0]) + hex2(rgb[1]) + hex2(rgb[2]);
            }
            return v;
        }
        if (node.nodeName.toLowerCase() == 'html')
            break;
        node = node.parentNode; // keep walking if transparent
    }
    return '#ffffff';
}

function getWidth(fx, i, width) {
    switch(fx) {
    case 'round':  return Math.round(width*(1-Math.cos(Math.asin(i/width))));
    case 'cool':   return Math.round(width*(1+Math.cos(Math.asin(i/width))));
    case 'sharp':  return width-i;
    case 'bite':   return Math.round(width*(Math.cos(Math.asin((width-i-1)/width))));
    case 'slide':  return Math.round(width*(Math.atan2(i,width/i)));
    case 'jut':    return Math.round(width*(Math.atan2(width,(width-i-1))));
    case 'curl':   return Math.round(width*(Math.atan(i)));
    case 'tear':   return Math.round(width*(Math.cos(i)));
    case 'wicked': return Math.round(width*(Math.tan(i)));
    case 'long':   return Math.round(width*(Math.sqrt(i)));
    case 'sculpt': return Math.round(width*(Math.log((width-i-1),width)));
    case 'dogfold':
    case 'dog':    return (i&1) ? (i+1) : width;
    case 'dog2':   return (i&2) ? (i+1) : width;
    case 'dog3':   return (i&3) ? (i+1) : width;
    case 'fray':   return (i%2)*width;
    case 'notch':  return width;
    case 'bevelfold':
    case 'bevel':  return i+1;
    case 'steep':  return i/2 + 1;
    case 'invsteep':return (width-i)/2+1;
    }
}

$.fn.corner = function(options) {
    // in 1.3+ we can fix mistakes with the ready state
    if (this.length === 0) {
        if (!$.isReady && this.selector) {
            var s = this.selector, c = this.context;
            $(function() {
                $(s,c).corner(options);
            });
        }
        return this;
    }

    return this.each(function(index){
        var $this = $(this),
            // meta values override options
            o = [$this.attr($.fn.corner.defaults.metaAttr) || '', options || ''].join(' ').toLowerCase(),
            keep = /keep/.test(o),                       // keep borders?
            cc = ((o.match(/cc:(#[0-9a-f]+)/)||[])[1]),  // corner color
            sc = ((o.match(/sc:(#[0-9a-f]+)/)||[])[1]),  // strip color
            width = parseInt((o.match(/(\d+)px/)||[])[1],10) || 10, // corner width
            re = /round|bevelfold|bevel|notch|bite|cool|sharp|slide|jut|curl|tear|fray|wicked|sculpt|long|dog3|dog2|dogfold|dog|invsteep|steep/,
            fx = ((o.match(re)||['round'])[0]),
            fold = /dogfold|bevelfold/.test(o),
            edges = { T:0, B:1 },
            opts = {
                TL:  /top|tl|left/.test(o),       TR:  /top|tr|right/.test(o),
                BL:  /bottom|bl|left/.test(o),    BR:  /bottom|br|right/.test(o)
            },
            // vars used in func later
            strip, pad, cssHeight, j, bot, d, ds, bw, i, w, e, c, common, $horz;

        if ( !opts.TL && !opts.TR && !opts.BL && !opts.BR )
            opts = { TL:1, TR:1, BL:1, BR:1 };

        // support native rounding
        if ($.fn.corner.defaults.useNative && fx == 'round' && (radius || moz || webkit) && !cc && !sc) {
            if (opts.TL)
                $this.css(radius ? 'border-top-left-radius' : moz ? '-moz-border-radius-topleft' : '-webkit-border-top-left-radius', width + 'px');
            if (opts.TR)
                $this.css(radius ? 'border-top-right-radius' : moz ? '-moz-border-radius-topright' : '-webkit-border-top-right-radius', width + 'px');
            if (opts.BL)
                $this.css(radius ? 'border-bottom-left-radius' : moz ? '-moz-border-radius-bottomleft' : '-webkit-border-bottom-left-radius', width + 'px');
            if (opts.BR)
                $this.css(radius ? 'border-bottom-right-radius' : moz ? '-moz-border-radius-bottomright' : '-webkit-border-bottom-right-radius', width + 'px');
            return;
        }

        strip = document.createElement('div');
        $(strip).css({
            overflow: 'hidden',
            height: '1px',
            minHeight: '1px',
            fontSize: '1px',
            backgroundColor: sc || 'transparent',
            borderStyle: 'solid'
        });

        pad = {
            T: parseInt($.css(this,'paddingTop'),10)||0,     R: parseInt($.css(this,'paddingRight'),10)||0,
            B: parseInt($.css(this,'paddingBottom'),10)||0,  L: parseInt($.css(this,'paddingLeft'),10)||0
        };

        if (typeof this.style.zoom !== undefined) this.style.zoom = 1; // force 'hasLayout' in IE
        if (!keep) this.style.border = 'none';
        strip.style.borderColor = cc || gpc(this.parentNode);
        cssHeight = $(this).outerHeight();

        for (j in edges) {
            bot = edges[j];
            // only add stips if needed
            if ((bot && (opts.BL || opts.BR)) || (!bot && (opts.TL || opts.TR))) {
                strip.style.borderStyle = 'none '+(opts[j+'R']?'solid':'none')+' none '+(opts[j+'L']?'solid':'none');
                d = document.createElement('div');
                $(d).addClass('jquery-corner');
                ds = d.style;

                bot ? this.appendChild(d) : this.insertBefore(d, this.firstChild);

                if (bot && cssHeight != 'auto') {
                    if ($.css(this,'position') == 'static')
                        this.style.position = 'relative';
                    ds.position = 'absolute';
                    ds.bottom = ds.left = ds.padding = ds.margin = '0';
                    if (expr)
                        ds.setExpression('width', 'this.parentNode.offsetWidth');
                    else
                        ds.width = '100%';
                }
                else if (!bot && msie) {
                    if ($.css(this,'position') == 'static')
                        this.style.position = 'relative';
                    ds.position = 'absolute';
                    ds.top = ds.left = ds.right = ds.padding = ds.margin = '0';

                    // fix ie6 problem when blocked element has a border width
                    if (expr) {
                        bw = sz(this,'borderLeftWidth') + sz(this,'borderRightWidth');
                        ds.setExpression('width', 'this.parentNode.offsetWidth - '+bw+'+ "px"');
                    }
                    else
                        ds.width = '100%';
                }
                else {
                    ds.position = 'relative';
                    ds.margin = !bot ? '-'+pad.T+'px -'+pad.R+'px '+(pad.T-width)+'px -'+pad.L+'px' :
                                        (pad.B-width)+'px -'+pad.R+'px -'+pad.B+'px -'+pad.L+'px';
                }

                for (i=0; i < width; i++) {
                    w = Math.max(0,getWidth(fx,i, width));
                    e = strip.cloneNode(false);
                    e.style.borderWidth = '0 '+(opts[j+'R']?w:0)+'px 0 '+(opts[j+'L']?w:0)+'px';
                    bot ? d.appendChild(e) : d.insertBefore(e, d.firstChild);
                }

                if (fold && $.support.boxModel) {
                    if (bot && noBottomFold) continue;
                    for (c in opts) {
                        if (!opts[c]) continue;
                        if (bot && (c == 'TL' || c == 'TR')) continue;
                        if (!bot && (c == 'BL' || c == 'BR')) continue;

                        common = { position: 'absolute', border: 'none', margin: 0, padding: 0, overflow: 'hidden', backgroundColor: strip.style.borderColor };
                        $horz = $('<div/>').css(common).css({ width: width + 'px', height: '1px' });
                        switch(c) {
                        case 'TL': $horz.css({ bottom: 0, left: 0 }); break;
                        case 'TR': $horz.css({ bottom: 0, right: 0 }); break;
                        case 'BL': $horz.css({ top: 0, left: 0 }); break;
                        case 'BR': $horz.css({ top: 0, right: 0 }); break;
                        }
                        d.appendChild($horz[0]);

                        var $vert = $('<div/>').css(common).css({ top: 0, bottom: 0, width: '1px', height: width + 'px' });
                        switch(c) {
                        case 'TL': $vert.css({ left: width }); break;
                        case 'TR': $vert.css({ right: width }); break;
                        case 'BL': $vert.css({ left: width }); break;
                        case 'BR': $vert.css({ right: width }); break;
                        }
                        d.appendChild($vert[0]);
                    }
                }
            }
        }
    });
};

$.fn.uncorner = function() {
    if (radius || moz || webkit)
        this.css(radius ? 'border-radius' : moz ? '-moz-border-radius' : '-webkit-border-radius', 0);
    $('div.jquery-corner', this).remove();
    return this;
};

// expose options
$.fn.corner.defaults = {
    useNative: true, // true if plugin should attempt to use native browser support for border radius rounding
    metaAttr:  'data-corner' // name of meta attribute to use for options
};

})(jQuery);
/*!
 * jQuery Mousewheel 3.1.12
 *
 * Copyright 2014 jQuery Foundation and other contributors
 * Released under the MIT license.
 * http://jquery.org/license
 */


(function (factory) {
    if ( typeof define === 'function' && define.amd ) {
        // AMD. Register as an anonymous module.
        define(['jquery'], factory);
    } else if (typeof exports === 'object') {
        // Node/CommonJS style for Browserify
        module.exports = factory;
    } else {
        // Browser globals
        factory(jQuery);
    }
}(function ($) {

    var toFix  = ['wheel', 'mousewheel', 'DOMMouseScroll', 'MozMousePixelScroll'],
        toBind = ( 'onwheel' in document || document.documentMode >= 9 ) ?
                    ['wheel'] : ['mousewheel', 'DomMouseScroll', 'MozMousePixelScroll'],
        slice  = Array.prototype.slice,
        nullLowestDeltaTimeout, lowestDelta;

    if ( $.event.fixHooks ) {
        for ( var i = toFix.length; i; ) {
            $.event.fixHooks[ toFix[--i] ] = $.event.mouseHooks;
        }
    }

    var special = $.event.special.mousewheel = {
        version: '3.1.12',

        setup: function() {
            if ( this.addEventListener ) {
                for ( var i = toBind.length; i; ) {
                    this.addEventListener( toBind[--i], handler, false );
                }
            } else {
                this.onmousewheel = handler;
            }
            // Store the line height and page height for this particular element
            $.data(this, 'mousewheel-line-height', special.getLineHeight(this));
            $.data(this, 'mousewheel-page-height', special.getPageHeight(this));
        },

        teardown: function() {
            if ( this.removeEventListener ) {
                for ( var i = toBind.length; i; ) {
                    this.removeEventListener( toBind[--i], handler, false );
                }
            } else {
                this.onmousewheel = null;
            }
            // Clean up the data we added to the element
            $.removeData(this, 'mousewheel-line-height');
            $.removeData(this, 'mousewheel-page-height');
        },

        getLineHeight: function(elem) {
            var $elem = $(elem),
                $parent = $elem['offsetParent' in $.fn ? 'offsetParent' : 'parent']();
            if (!$parent.length) {
                $parent = $('body');
            }
            return parseInt($parent.css('fontSize'), 10) || parseInt($elem.css('fontSize'), 10) || 16;
        },

        getPageHeight: function(elem) {
            return $(elem).height();
        },

        settings: {
            adjustOldDeltas: true, // see shouldAdjustOldDeltas() below
            normalizeOffset: true  // calls getBoundingClientRect for each event
        }
    };

    $.fn.extend({
        mousewheel: function(fn) {
            return fn ? this.bind('mousewheel', fn) : this.trigger('mousewheel');
        },

        unmousewheel: function(fn) {
            return this.unbind('mousewheel', fn);
        }
    });


    function handler(event) {
        var orgEvent   = event || window.event,
            args       = slice.call(arguments, 1),
            delta      = 0,
            deltaX     = 0,
            deltaY     = 0,
            absDelta   = 0,
            offsetX    = 0,
            offsetY    = 0;
        event = $.event.fix(orgEvent);
        event.type = 'mousewheel';

        // Old school scrollwheel delta
        if ( 'detail'      in orgEvent ) { deltaY = orgEvent.detail * -1;      }
        if ( 'wheelDelta'  in orgEvent ) { deltaY = orgEvent.wheelDelta;       }
        if ( 'wheelDeltaY' in orgEvent ) { deltaY = orgEvent.wheelDeltaY;      }
        if ( 'wheelDeltaX' in orgEvent ) { deltaX = orgEvent.wheelDeltaX * -1; }

        // Firefox < 17 horizontal scrolling related to DOMMouseScroll event
        if ( 'axis' in orgEvent && orgEvent.axis === orgEvent.HORIZONTAL_AXIS ) {
            deltaX = deltaY * -1;
            deltaY = 0;
        }

        // Set delta to be deltaY or deltaX if deltaY is 0 for backwards compatabilitiy
        delta = deltaY === 0 ? deltaX : deltaY;

        // New school wheel delta (wheel event)
        if ( 'deltaY' in orgEvent ) {
            deltaY = orgEvent.deltaY * -1;
            delta  = deltaY;
        }
        if ( 'deltaX' in orgEvent ) {
            deltaX = orgEvent.deltaX;
            if ( deltaY === 0 ) { delta  = deltaX * -1; }
        }

        // No change actually happened, no reason to go any further
        if ( deltaY === 0 && deltaX === 0 ) { return; }

        // Need to convert lines and pages to pixels if we aren't already in pixels
        // There are three delta modes:
        //   * deltaMode 0 is by pixels, nothing to do
        //   * deltaMode 1 is by lines
        //   * deltaMode 2 is by pages
        if ( orgEvent.deltaMode === 1 ) {
            var lineHeight = $.data(this, 'mousewheel-line-height');
            delta  *= lineHeight;
            deltaY *= lineHeight;
            deltaX *= lineHeight;
        } else if ( orgEvent.deltaMode === 2 ) {
            var pageHeight = $.data(this, 'mousewheel-page-height');
            delta  *= pageHeight;
            deltaY *= pageHeight;
            deltaX *= pageHeight;
        }

        // Store lowest absolute delta to normalize the delta values
        absDelta = Math.max( Math.abs(deltaY), Math.abs(deltaX) );

        if ( !lowestDelta || absDelta < lowestDelta ) {
            lowestDelta = absDelta;

            // Adjust older deltas if necessary
            if ( shouldAdjustOldDeltas(orgEvent, absDelta) ) {
                lowestDelta /= 40;
            }
        }

        // Adjust older deltas if necessary
        if ( shouldAdjustOldDeltas(orgEvent, absDelta) ) {
            // Divide all the things by 40!
            delta  /= 40;
            deltaX /= 40;
            deltaY /= 40;
        }

        // Get a whole, normalized value for the deltas
        delta  = Math[ delta  >= 1 ? 'floor' : 'ceil' ](delta  / lowestDelta);
        deltaX = Math[ deltaX >= 1 ? 'floor' : 'ceil' ](deltaX / lowestDelta);
        deltaY = Math[ deltaY >= 1 ? 'floor' : 'ceil' ](deltaY / lowestDelta);

        // Normalise offsetX and offsetY properties
        if ( special.settings.normalizeOffset && this.getBoundingClientRect ) {
            var boundingRect = this.getBoundingClientRect();
            offsetX = event.clientX - boundingRect.left;
            offsetY = event.clientY - boundingRect.top;
        }

        // Add information to the event object
        event.deltaX = deltaX;
        event.deltaY = deltaY;
        event.deltaFactor = lowestDelta;
        event.offsetX = offsetX;
        event.offsetY = offsetY;
        // Go ahead and set deltaMode to 0 since we converted to pixels
        // Although this is a little odd since we overwrite the deltaX/Y
        // properties with normalized deltas.
        event.deltaMode = 0;

        // Add event and delta to the front of the arguments
        args.unshift(event, delta, deltaX, deltaY);

        // Clearout lowestDelta after sometime to better
        // handle multiple device types that give different
        // a different lowestDelta
        // Ex: trackpad = 3 and mouse wheel = 120
        if (nullLowestDeltaTimeout) { clearTimeout(nullLowestDeltaTimeout); }
        nullLowestDeltaTimeout = setTimeout(nullLowestDelta, 200);

        return ($.event.dispatch || $.event.handle).apply(this, args);
    }

    function nullLowestDelta() {
        lowestDelta = null;
    }

    function shouldAdjustOldDeltas(orgEvent, absDelta) {
        // If this is an older event and the delta is divisable by 120,
        // then we are assuming that the browser is treating this as an
        // older mouse wheel event and that we should divide the deltas
        // by 40 to try and get a more usable deltaFactor.
        // Side note, this actually impacts the reported scroll distance
        // in older browsers and can cause scrolling to be slower than native.
        // Turn this off by setting $.event.special.mousewheel.settings.adjustOldDeltas to false.
        return special.settings.adjustOldDeltas && orgEvent.type === 'mousewheel' && absDelta % 120 === 0;
    }
}));
(function($){
	var initLayout = function() {
		var hash = window.location.hash.replace('#', '');
		var currentTab = $('ul.navigationTabs a')
							.bind('click', showTab);
		if (currentTab.size() == 0) {
			currentTab = $('ul.navigationTabs a:first');
		}
		showTab.apply(currentTab.get(0));
		$('#colorpickerHolder').ColorPicker({flat: true});
		$('#colorpickerHolder2').ColorPicker({
			flat: true,
			color: '#00ff00',
			onSubmit: function(hsb, hex, rgb) {
				$('#colorSelector2 div').css('backgroundColor', '#' + hex);
			}
		});
		$('#colorpickerHolder2>div').css('position', 'absolute');
		var widt = false;
		$('#colorSelector2').bind('click', function() {
			$('#colorpickerHolder2').stop().animate({height: widt ? 0 : 173}, 500);
			widt = !widt;
		});
		$('#colorpickerField1, #colorpickerField2, #colorpickerField3').ColorPicker({
			onSubmit: function(hsb, hex, rgb, el) {
				$(el).val(hex);
				$(el).ColorPickerHide();
			},
			onBeforeShow: function () {
				$(this).ColorPickerSetColor(this.value);
			}
		})
		.bind('keyup', function(){
			$(this).ColorPickerSetColor(this.value);
		});
		$('#colorSelector').ColorPicker({
			color: '#0000ff',
			onShow: function (colpkr) {
				$(colpkr).fadeIn(500);
				return false;
			},
			onHide: function (colpkr) {
				$(colpkr).fadeOut(500);
				return false;
			},
			onChange: function (hsb, hex, rgb) {
				$('#colorSelector div').css('backgroundColor', '#' + hex);
			}
		});
	};

	var showTab = function(e) {
		var tabIndex = $('ul.navigationTabs a')
							.removeClass('active')
							.index(this);
		$(this)
			.addClass('active')
			.blur();
		$('div.tab')
			.hide()
				.eq(tabIndex)
				.show();
	};

	EYE.register(initLayout, 'init');
})(jQuery)
;
/*
 * A JavaScript implementation of the RSA Data Security, Inc. MD5 Message
 * Digest Algorithm, as defined in RFC 1321.
 * Version 2.2 Copyright (C) Paul Johnston 1999 - 2009
 * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
 * Distributed under the BSD License
 * See http://pajhome.org.uk/crypt/md5 for more info.
 */

/*
 * Configurable variables. You may need to tweak these to be compatible with
 * the server-side, but the defaults work in most cases.
 */

var hexcase = 0;   /* hex output format. 0 - lowercase; 1 - uppercase        */
var b64pad  = "";  /* base-64 pad character. "=" for strict RFC compliance   */

/*
 * These are the functions you'll usually want to call
 * They take string arguments and return either hex or base-64 encoded strings
 */
function hex_md5(s)    { return rstr2hex(rstr_md5(str2rstr_utf8(s))); }
function b64_md5(s)    { return rstr2b64(rstr_md5(str2rstr_utf8(s))); }
function any_md5(s, e) { return rstr2any(rstr_md5(str2rstr_utf8(s)), e); }
function hex_hmac_md5(k, d)
  { return rstr2hex(rstr_hmac_md5(str2rstr_utf8(k), str2rstr_utf8(d))); }
function b64_hmac_md5(k, d)
  { return rstr2b64(rstr_hmac_md5(str2rstr_utf8(k), str2rstr_utf8(d))); }
function any_hmac_md5(k, d, e)
  { return rstr2any(rstr_hmac_md5(str2rstr_utf8(k), str2rstr_utf8(d)), e); }

/*
 * Perform a simple self-test to see if the VM is working
 */
function md5_vm_test()
{
  return hex_md5("abc").toLowerCase() == "900150983cd24fb0d6963f7d28e17f72";
}

/*
 * Calculate the MD5 of a raw string
 */
function rstr_md5(s)
{
  return binl2rstr(binl_md5(rstr2binl(s), s.length * 8));
}

/*
 * Calculate the HMAC-MD5, of a key and some data (raw strings)
 */
function rstr_hmac_md5(key, data)
{
  var bkey = rstr2binl(key);
  if(bkey.length > 16) bkey = binl_md5(bkey, key.length * 8);

  var ipad = Array(16), opad = Array(16);
  for(var i = 0; i < 16; i++)
  {
    ipad[i] = bkey[i] ^ 0x36363636;
    opad[i] = bkey[i] ^ 0x5C5C5C5C;
  }

  var hash = binl_md5(ipad.concat(rstr2binl(data)), 512 + data.length * 8);
  return binl2rstr(binl_md5(opad.concat(hash), 512 + 128));
}

/*
 * Convert a raw string to a hex string
 */
function rstr2hex(input)
{
  try { hexcase } catch(e) { hexcase=0; }
  var hex_tab = hexcase ? "0123456789ABCDEF" : "0123456789abcdef";
  var output = "";
  var x;
  for(var i = 0; i < input.length; i++)
  {
    x = input.charCodeAt(i);
    output += hex_tab.charAt((x >>> 4) & 0x0F)
           +  hex_tab.charAt( x        & 0x0F);
  }
  return output;
}

/*
 * Convert a raw string to a base-64 string
 */
function rstr2b64(input)
{
  try { b64pad } catch(e) { b64pad=''; }
  var tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  var output = "";
  var len = input.length;
  for(var i = 0; i < len; i += 3)
  {
    var triplet = (input.charCodeAt(i) << 16)
                | (i + 1 < len ? input.charCodeAt(i+1) << 8 : 0)
                | (i + 2 < len ? input.charCodeAt(i+2)      : 0);
    for(var j = 0; j < 4; j++)
    {
      if(i * 8 + j * 6 > input.length * 8) output += b64pad;
      else output += tab.charAt((triplet >>> 6*(3-j)) & 0x3F);
    }
  }
  return output;
}

/*
 * Convert a raw string to an arbitrary string encoding
 */
function rstr2any(input, encoding)
{
  var divisor = encoding.length;
  var i, j, q, x, quotient;

  /* Convert to an array of 16-bit big-endian values, forming the dividend */
  var dividend = Array(Math.ceil(input.length / 2));
  for(i = 0; i < dividend.length; i++)
  {
    dividend[i] = (input.charCodeAt(i * 2) << 8) | input.charCodeAt(i * 2 + 1);
  }

  /*
   * Repeatedly perform a long division. The binary array forms the dividend,
   * the length of the encoding is the divisor. Once computed, the quotient
   * forms the dividend for the next step. All remainders are stored for later
   * use.
   */
  var full_length = Math.ceil(input.length * 8 /
                                    (Math.log(encoding.length) / Math.log(2)));
  var remainders = Array(full_length);
  for(j = 0; j < full_length; j++)
  {
    quotient = Array();
    x = 0;
    for(i = 0; i < dividend.length; i++)
    {
      x = (x << 16) + dividend[i];
      q = Math.floor(x / divisor);
      x -= q * divisor;
      if(quotient.length > 0 || q > 0)
        quotient[quotient.length] = q;
    }
    remainders[j] = x;
    dividend = quotient;
  }

  /* Convert the remainders to the output string */
  var output = "";
  for(i = remainders.length - 1; i >= 0; i--)
    output += encoding.charAt(remainders[i]);

  return output;
}

/*
 * Encode a string as utf-8.
 * For efficiency, this assumes the input is valid utf-16.
 */
function str2rstr_utf8(input)
{
  var output = "";
  var i = -1;
  var x, y;

  while(++i < input.length)
  {
    /* Decode utf-16 surrogate pairs */
    x = input.charCodeAt(i);
    y = i + 1 < input.length ? input.charCodeAt(i + 1) : 0;
    if(0xD800 <= x && x <= 0xDBFF && 0xDC00 <= y && y <= 0xDFFF)
    {
      x = 0x10000 + ((x & 0x03FF) << 10) + (y & 0x03FF);
      i++;
    }

    /* Encode output as utf-8 */
    if(x <= 0x7F)
      output += String.fromCharCode(x);
    else if(x <= 0x7FF)
      output += String.fromCharCode(0xC0 | ((x >>> 6 ) & 0x1F),
                                    0x80 | ( x         & 0x3F));
    else if(x <= 0xFFFF)
      output += String.fromCharCode(0xE0 | ((x >>> 12) & 0x0F),
                                    0x80 | ((x >>> 6 ) & 0x3F),
                                    0x80 | ( x         & 0x3F));
    else if(x <= 0x1FFFFF)
      output += String.fromCharCode(0xF0 | ((x >>> 18) & 0x07),
                                    0x80 | ((x >>> 12) & 0x3F),
                                    0x80 | ((x >>> 6 ) & 0x3F),
                                    0x80 | ( x         & 0x3F));
  }
  return output;
}

/*
 * Encode a string as utf-16
 */
function str2rstr_utf16le(input)
{
  var output = "";
  for(var i = 0; i < input.length; i++)
    output += String.fromCharCode( input.charCodeAt(i)        & 0xFF,
                                  (input.charCodeAt(i) >>> 8) & 0xFF);
  return output;
}

function str2rstr_utf16be(input)
{
  var output = "";
  for(var i = 0; i < input.length; i++)
    output += String.fromCharCode((input.charCodeAt(i) >>> 8) & 0xFF,
                                   input.charCodeAt(i)        & 0xFF);
  return output;
}

/*
 * Convert a raw string to an array of little-endian words
 * Characters >255 have their high-byte silently ignored.
 */
function rstr2binl(input)
{
  var output = Array(input.length >> 2);
  for(var i = 0; i < output.length; i++)
    output[i] = 0;
  for(var i = 0; i < input.length * 8; i += 8)
    output[i>>5] |= (input.charCodeAt(i / 8) & 0xFF) << (i%32);
  return output;
}

/*
 * Convert an array of little-endian words to a string
 */
function binl2rstr(input)
{
  var output = "";
  for(var i = 0; i < input.length * 32; i += 8)
    output += String.fromCharCode((input[i>>5] >>> (i % 32)) & 0xFF);
  return output;
}

/*
 * Calculate the MD5 of an array of little-endian words, and a bit length.
 */
function binl_md5(x, len)
{
  /* append padding */
  x[len >> 5] |= 0x80 << ((len) % 32);
  x[(((len + 64) >>> 9) << 4) + 14] = len;

  var a =  1732584193;
  var b = -271733879;
  var c = -1732584194;
  var d =  271733878;

  for(var i = 0; i < x.length; i += 16)
  {
    var olda = a;
    var oldb = b;
    var oldc = c;
    var oldd = d;

    a = md5_ff(a, b, c, d, x[i+ 0], 7 , -680876936);
    d = md5_ff(d, a, b, c, x[i+ 1], 12, -389564586);
    c = md5_ff(c, d, a, b, x[i+ 2], 17,  606105819);
    b = md5_ff(b, c, d, a, x[i+ 3], 22, -1044525330);
    a = md5_ff(a, b, c, d, x[i+ 4], 7 , -176418897);
    d = md5_ff(d, a, b, c, x[i+ 5], 12,  1200080426);
    c = md5_ff(c, d, a, b, x[i+ 6], 17, -1473231341);
    b = md5_ff(b, c, d, a, x[i+ 7], 22, -45705983);
    a = md5_ff(a, b, c, d, x[i+ 8], 7 ,  1770035416);
    d = md5_ff(d, a, b, c, x[i+ 9], 12, -1958414417);
    c = md5_ff(c, d, a, b, x[i+10], 17, -42063);
    b = md5_ff(b, c, d, a, x[i+11], 22, -1990404162);
    a = md5_ff(a, b, c, d, x[i+12], 7 ,  1804603682);
    d = md5_ff(d, a, b, c, x[i+13], 12, -40341101);
    c = md5_ff(c, d, a, b, x[i+14], 17, -1502002290);
    b = md5_ff(b, c, d, a, x[i+15], 22,  1236535329);

    a = md5_gg(a, b, c, d, x[i+ 1], 5 , -165796510);
    d = md5_gg(d, a, b, c, x[i+ 6], 9 , -1069501632);
    c = md5_gg(c, d, a, b, x[i+11], 14,  643717713);
    b = md5_gg(b, c, d, a, x[i+ 0], 20, -373897302);
    a = md5_gg(a, b, c, d, x[i+ 5], 5 , -701558691);
    d = md5_gg(d, a, b, c, x[i+10], 9 ,  38016083);
    c = md5_gg(c, d, a, b, x[i+15], 14, -660478335);
    b = md5_gg(b, c, d, a, x[i+ 4], 20, -405537848);
    a = md5_gg(a, b, c, d, x[i+ 9], 5 ,  568446438);
    d = md5_gg(d, a, b, c, x[i+14], 9 , -1019803690);
    c = md5_gg(c, d, a, b, x[i+ 3], 14, -187363961);
    b = md5_gg(b, c, d, a, x[i+ 8], 20,  1163531501);
    a = md5_gg(a, b, c, d, x[i+13], 5 , -1444681467);
    d = md5_gg(d, a, b, c, x[i+ 2], 9 , -51403784);
    c = md5_gg(c, d, a, b, x[i+ 7], 14,  1735328473);
    b = md5_gg(b, c, d, a, x[i+12], 20, -1926607734);

    a = md5_hh(a, b, c, d, x[i+ 5], 4 , -378558);
    d = md5_hh(d, a, b, c, x[i+ 8], 11, -2022574463);
    c = md5_hh(c, d, a, b, x[i+11], 16,  1839030562);
    b = md5_hh(b, c, d, a, x[i+14], 23, -35309556);
    a = md5_hh(a, b, c, d, x[i+ 1], 4 , -1530992060);
    d = md5_hh(d, a, b, c, x[i+ 4], 11,  1272893353);
    c = md5_hh(c, d, a, b, x[i+ 7], 16, -155497632);
    b = md5_hh(b, c, d, a, x[i+10], 23, -1094730640);
    a = md5_hh(a, b, c, d, x[i+13], 4 ,  681279174);
    d = md5_hh(d, a, b, c, x[i+ 0], 11, -358537222);
    c = md5_hh(c, d, a, b, x[i+ 3], 16, -722521979);
    b = md5_hh(b, c, d, a, x[i+ 6], 23,  76029189);
    a = md5_hh(a, b, c, d, x[i+ 9], 4 , -640364487);
    d = md5_hh(d, a, b, c, x[i+12], 11, -421815835);
    c = md5_hh(c, d, a, b, x[i+15], 16,  530742520);
    b = md5_hh(b, c, d, a, x[i+ 2], 23, -995338651);

    a = md5_ii(a, b, c, d, x[i+ 0], 6 , -198630844);
    d = md5_ii(d, a, b, c, x[i+ 7], 10,  1126891415);
    c = md5_ii(c, d, a, b, x[i+14], 15, -1416354905);
    b = md5_ii(b, c, d, a, x[i+ 5], 21, -57434055);
    a = md5_ii(a, b, c, d, x[i+12], 6 ,  1700485571);
    d = md5_ii(d, a, b, c, x[i+ 3], 10, -1894986606);
    c = md5_ii(c, d, a, b, x[i+10], 15, -1051523);
    b = md5_ii(b, c, d, a, x[i+ 1], 21, -2054922799);
    a = md5_ii(a, b, c, d, x[i+ 8], 6 ,  1873313359);
    d = md5_ii(d, a, b, c, x[i+15], 10, -30611744);
    c = md5_ii(c, d, a, b, x[i+ 6], 15, -1560198380);
    b = md5_ii(b, c, d, a, x[i+13], 21,  1309151649);
    a = md5_ii(a, b, c, d, x[i+ 4], 6 , -145523070);
    d = md5_ii(d, a, b, c, x[i+11], 10, -1120210379);
    c = md5_ii(c, d, a, b, x[i+ 2], 15,  718787259);
    b = md5_ii(b, c, d, a, x[i+ 9], 21, -343485551);

    a = safe_add(a, olda);
    b = safe_add(b, oldb);
    c = safe_add(c, oldc);
    d = safe_add(d, oldd);
  }
  return Array(a, b, c, d);
}

/*
 * These functions implement the four basic operations the algorithm uses.
 */
function md5_cmn(q, a, b, x, s, t)
{
  return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s),b);
}
function md5_ff(a, b, c, d, x, s, t)
{
  return md5_cmn((b & c) | ((~b) & d), a, b, x, s, t);
}
function md5_gg(a, b, c, d, x, s, t)
{
  return md5_cmn((b & d) | (c & (~d)), a, b, x, s, t);
}
function md5_hh(a, b, c, d, x, s, t)
{
  return md5_cmn(b ^ c ^ d, a, b, x, s, t);
}
function md5_ii(a, b, c, d, x, s, t)
{
  return md5_cmn(c ^ (b | (~d)), a, b, x, s, t);
}

/*
 * Add integers, wrapping at 2^32. This uses 16-bit operations internally
 * to work around bugs in some JS interpreters.
 */
function safe_add(x, y)
{
  var lsw = (x & 0xFFFF) + (y & 0xFFFF);
  var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
  return (msw << 16) | (lsw & 0xFFFF);
}

/*
 * Bitwise rotate a 32-bit number to the left.
 */
function bit_rol(num, cnt)
{
  return (num << cnt) | (num >>> (32 - cnt));
}
;
/**
 * @fileoverview This file contains the code that manages the construction and updates for the 
 *	   metadata panel. The metadata panel contains the details that describes a given crop. This
 *	   information includes required elements such as title, size, position, and rotation, but also
 *	   includes site-specific variables defined in the *-persistence-manager.js files. (See these
 *	   files for details.)
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */


MetadataManager = {};

/**
 * Saves information describing the current crop to the persistence manager.
 */

MetadataManager.saveMetadata = function()
{
	if (CropManager.selectedCrop !== null)
	{
		CropManager.selectCrop(CropManager.selectedCrop);
		PersistenceManager.saveCrop(CropManager.selectedCrop);
		this.refresh();
		CropManager.selectCrop(CropManager.selectedCrop);
		ControlManager.showCropControls(crop);
	}
	else
		MetadataManager.hideCropDetails();
};

/**
 * Populates the metadata form with a crop's details.
 *
 * @param {Object} crop The currently-selected crop.
 */
 
MetadataManager.showCropDetails = function(crop)
{
	$("li.crop-list-item").each(function()
	{
		$(this).removeClass("crop-list-selected");
	});
		
	$("li#" + crop.uuid).addClass("crop-list-selected");

	ControlManager.showCropControls(crop);
	ControlManager.toFront();
};

MetadataManager.showDirtyCrop = function(crop)
{
	$("li#" + crop.uuid).addClass("dirty");
};


/**
 * Hide any visible crop details / clear the metadata form. Invoked when no crop is currently 
 *	   selected.
 */

MetadataManager.hideCropDetails = function()
{
	$("div#metadata").css("display", "none");

	$("li.crop-list-item").each(function()
	{
		$(this).removeClass("crop-list-selected");
	});
	
	ControlManager.hideCropControls();
	ControlManager.toFront();
};

/**
 * Refreshes the crop list (typically found in the upper-right) with the latest crops.
 */

MetadataManager.refresh = function()
{
	$("ul#sortable").html("");

	var i = CropManager.crops.length;

	for (i = CropManager.crops.length; i > 0; i--)
	{
		var crop = CropManager.crops[i - 1];
		
		$("ul#sortable").append("<li id=\"" + crop.uuid + "\" class=\"crop-list-item\">" + 
								crop.metadata.title + "</li>");
								
		if (crop.dirty)
		{
			$("li#" + crop.uuid).addClass("dirty");
		}
	}

	// Add a selection handler that loads the metadata (showCropDetails) when an crop is selected
	// from the list.
	
	$("li.crop-list-item").click(function()
	{
		var deselect = $(this).hasClass("crop-list-selected");
		
		$("li.crop-list-item").each(function()
		{
			$(this).removeClass("crop-list-selected");
		});

		if (!deselect)
		{
			var i = 0;
			for (i = 0; i < CropManager.crops.length; i++)
			{
				var crop = CropManager.crops[i];
			
				if (crop.uuid === $(this).attr("id"))
				{
					if (crop.setViewPort !== undefined)
					{
						crop.setViewPort();
					}
					
					CropManager.selectCrop(crop);
				}
			}
		}
		else
		{
			CropManager.selectCrop(null);
		}
	});

	$("#sortable").sortable(
	{
		update: function(event, ui)
		{
			var items = $("#sortable").sortable("toArray");

			var i = 0;
			for (i = items.length; i > 0; i--)
			{
				CropManager.bringToFront(items[i - 1]);
			}

			PersistenceManager.setCropOrder(items);
		}
	});
	
	var pos = $(CropTool.rootDiv).offset();

	$("#collection").css("left", (pos.left + 10) + "px");
	$("#collection").css("top", (pos.top + 10) + "px");

	if (CropManager.crops.length > 1)
		$("#collection").css("display", "block");
	else
		$("#collection").css("display", "none");
};

/**
 * Constructs the HTML for the crop details panel (lower-left) and crop list panel (upper-right).
 */
 
MetadataManager.initializeDetails = function()
{
	MetadataManager.cropController = {};
	
	// Build the details panel...
	
	this.refresh();
};
/*global $, CoordinateManager, Image */

// Fedora: ***REMOVED***

var ImageServer = {};

ImageServer.tile_size = 255;

function setImageParameters(element)
{
	ImageServer.imagePath = $(element).attr("xlink:href");

	ImageServer.details = {};

	ImageServer.details.levels = 0; // FIX

	ImageServer.details.o_width = parseInt($(element).attr("width"), 10);
	ImageServer.details.o_height = parseInt($(element).attr("height"), 10);

	ImageServer.details.width = ImageServer.tile_size * Math.ceil(ImageServer.details.o_width / (ImageServer.tile_size + 1));
	ImageServer.details.height = ImageServer.tile_size * Math.ceil(ImageServer.details.o_height / (ImageServer.tile_size + 1));

	var min_side = ImageServer.details.o_width;

	if (ImageServer.details.height > ImageServer.details.width)
		min_side = ImageServer.details.o_height;
		
	for (ImageServer.details.levels = 0; min_side >= (ImageServer.tile_size + 1); ImageServer.details.levels++)
		min_side = min_side / 2;

	CoordinateManager.initialize(ImageServer.details.width, ImageServer.details.height, ImageServer.details.levels);
	PersistenceManager.initialize(CropTool.identifier);
	ControlManager.initialize();
//	ControlManager.updateZoomWidget();
//	ControlManager.updateZoom(CoordinateManager.current_level);
};

ImageServer.initialize = function(image)
{
	this.image = image; 

/*
<svg:svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svg="http://www.w3.org/2000/svg">
	<svg:image x="0" y="0" width="5700" height="7200" xlink:href="inu-wint/inu-wint-26.10.jp2">
    	<svg:clipPath>
        	<svg:rect type="crop_then_rotate" x="3124" y="2841" width="1337" height="2039" transform="rotate(90)"></svg:rect>
                     
			<svg:rect type="rotate_then_crop" x="2320" y="3124" width="2039" height="1337" transform="rotate(90)"></svg:rect>
        </svg:clipPath>
	</svg:image>
</svg:svg>

-- OR --

<svg:svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svg="http://www.w3.org/2000/svg">
	<svg:image x="0" y="0" width="13210" height="9990" xlink:href="inu-wint/inu-wint-9.6.jp2">
		<svg:clipPath>
			<svg:rect x="2580" y="516" width="10630" height="8441"></svg:rect>
		</svg:clipPath>
	</svg:image>
</svg:svg>
*/

	var url = Site.fetchImageUrl(this.image);

	var me = this;
	
	$.ajax({ url: url, success: function(data) 
	{
		if (data.length === 0)
		{
			alert("ImageServer.initialize: Unable to fetch " + url + ". Check that everything is served from the same host.");
			return;
		}

		var svg_use = $(data).find("use");

		if (svg_use.length == 0)
			svg_use = $(data).find("svg\\:use");
		
		if (svg_use.length > 0) // Crop or parent?
		{
			svg_use.each(function() 
			{
				var use_url = $(this).attr("xlink:href");
				
				var toks = use_url.split("/");

				ImageServer.initialize(toks[5]);
			});
		}
		else
		{
			var svg_image = $(data).find("svg\\:image");
			
			if (svg_image.length == 0)
				svg_image = $(data).find("image");
				
			svg_image.each(function() 
			{
				setImageParameters(this);
			});
		}
	}, error: function(jqXHR, textStatus, errorThrown)
	{
		alert("ImageServer.initialize: Unable to fetch " + url + ". Check that everything is served from the same host.");
	}});

	CropTool.resize();
};

// Generic
ImageServer.queueImage = function (img_url, callback, context)
{
	var img = new Image();

	$(img).load(function()
	{
		$(this).hide();
		$("body").append(this);

		callback(this, context);
			
	}).error(function() 
	{
		callback(null, context); 

		$(this).remove();
	}).attr("src", img_url);
};

ImageServer.tileAt = function(i, j, level, size)
{
	if (i * size * Math.pow(2, ImageServer.details.levels - level) > ImageServer.details.width)
		return null;

	if (j * size * Math.pow(2, ImageServer.details.levels - level) > ImageServer.details.height)
		return null;

	return Site.tileUrl(ImageServer.imagePath, level, i, j)
};

ImageServer.fetchThumbnail = function(width, height, callback)
{
	var req_height = ImageServer.details.height;
	var req_width = ImageServer.details.width;
	
	if ((width / height) > (ImageServer.details.width / ImageServer.details.height))
	{
		width = Math.floor(ImageServer.details.width * (height / ImageServer.details.height));
	}
	else
	{
		height = Math.floor(ImageServer.details.height * (width / ImageServer.details.width));
	}
	
	if (req_width / width < req_height / height)
	{
		req_width = width * Math.floor(req_height / height);
		req_height = height * Math.floor(req_height / height);
	}
	else
	{
		req_width = width * Math.floor(req_width / width);
		req_height = height * Math.floor(req_width / width);
	}

	var url = Site.thumbnailImageUrl(this.image, width, height, req_width, req_height);

	var img = new Image();

	$(img).load(function()
	{
		$(this).hide();
		$("body").append(this);

		callback(this);
	}).attr("src", url);
};

ImageServer.ratioCoordinatesForRect = function(left, top, width, height, level)
{
	level = ImageServer.details.levels - level;
	
	var coords = {};
	coords.abs_top = top * Math.pow(2, level);
	coords.abs_left = left * Math.pow(2, level);
	coords.abs_width = width * Math.pow(2, level);
	coords.abs_height = height * Math.pow(2, level);

	coords.top = coords.abs_top / ImageServer.details.height;
	coords.left = coords.abs_left / ImageServer.details.width;
	coords.width = coords.abs_width / ImageServer.details.width;
	coords.height = coords.abs_height / ImageServer.details.height;
	
	return coords;
};


// ┌────────────────────────────────────────────────────────────────────┐ \\
// │ Raphaël 2.1.3 - JavaScript Vector Library                          │ \\
// ├────────────────────────────────────────────────────────────────────┤ \\
// │ Copyright © 2008-2012 Dmitry Baranovskiy (http://raphaeljs.com)    │ \\
// │ Copyright © 2008-2012 Sencha Labs (http://sencha.com)              │ \\
// ├────────────────────────────────────────────────────────────────────┤ \\
// │ Licensed under the MIT (http://raphaeljs.com/license.html) license.│ \\
// └────────────────────────────────────────────────────────────────────┘ \\
!function(a){var b,c,d="0.4.2",e="hasOwnProperty",f=/[\.\/]/,g="*",h=function(){},i=function(a,b){return a-b},j={n:{}},k=function(a,d){a=String(a);var e,f=c,g=Array.prototype.slice.call(arguments,2),h=k.listeners(a),j=0,l=[],m={},n=[],o=b;b=a,c=0;for(var p=0,q=h.length;q>p;p++)"zIndex"in h[p]&&(l.push(h[p].zIndex),h[p].zIndex<0&&(m[h[p].zIndex]=h[p]));for(l.sort(i);l[j]<0;)if(e=m[l[j++]],n.push(e.apply(d,g)),c)return c=f,n;for(p=0;q>p;p++)if(e=h[p],"zIndex"in e)if(e.zIndex==l[j]){if(n.push(e.apply(d,g)),c)break;do if(j++,e=m[l[j]],e&&n.push(e.apply(d,g)),c)break;while(e)}else m[e.zIndex]=e;else if(n.push(e.apply(d,g)),c)break;return c=f,b=o,n.length?n:null};k._events=j,k.listeners=function(a){var b,c,d,e,h,i,k,l,m=a.split(f),n=j,o=[n],p=[];for(e=0,h=m.length;h>e;e++){for(l=[],i=0,k=o.length;k>i;i++)for(n=o[i].n,c=[n[m[e]],n[g]],d=2;d--;)b=c[d],b&&(l.push(b),p=p.concat(b.f||[]));o=l}return p},k.on=function(a,b){if(a=String(a),"function"!=typeof b)return function(){};for(var c=a.split(f),d=j,e=0,g=c.length;g>e;e++)d=d.n,d=d.hasOwnProperty(c[e])&&d[c[e]]||(d[c[e]]={n:{}});for(d.f=d.f||[],e=0,g=d.f.length;g>e;e++)if(d.f[e]==b)return h;return d.f.push(b),function(a){+a==+a&&(b.zIndex=+a)}},k.f=function(a){var b=[].slice.call(arguments,1);return function(){k.apply(null,[a,null].concat(b).concat([].slice.call(arguments,0)))}},k.stop=function(){c=1},k.nt=function(a){return a?new RegExp("(?:\\.|\\/|^)"+a+"(?:\\.|\\/|$)").test(b):b},k.nts=function(){return b.split(f)},k.off=k.unbind=function(a,b){if(!a)return void(k._events=j={n:{}});var c,d,h,i,l,m,n,o=a.split(f),p=[j];for(i=0,l=o.length;l>i;i++)for(m=0;m<p.length;m+=h.length-2){if(h=[m,1],c=p[m].n,o[i]!=g)c[o[i]]&&h.push(c[o[i]]);else for(d in c)c[e](d)&&h.push(c[d]);p.splice.apply(p,h)}for(i=0,l=p.length;l>i;i++)for(c=p[i];c.n;){if(b){if(c.f){for(m=0,n=c.f.length;n>m;m++)if(c.f[m]==b){c.f.splice(m,1);break}!c.f.length&&delete c.f}for(d in c.n)if(c.n[e](d)&&c.n[d].f){var q=c.n[d].f;for(m=0,n=q.length;n>m;m++)if(q[m]==b){q.splice(m,1);break}!q.length&&delete c.n[d].f}}else{delete c.f;for(d in c.n)c.n[e](d)&&c.n[d].f&&delete c.n[d].f}c=c.n}},k.once=function(a,b){var c=function(){return k.unbind(a,c),b.apply(this,arguments)};return k.on(a,c)},k.version=d,k.toString=function(){return"You are running Eve "+d},"undefined"!=typeof module&&module.exports?module.exports=k:"undefined"!=typeof define?define("eve",[],function(){return k}):a.eve=k}(window||this),function(a,b){"function"==typeof define&&define.amd?define(["eve"],function(c){return b(a,c)}):b(a,a.eve||"function"==typeof require&&require("eve"))}(this,function(a,b){function c(a){if(c.is(a,"function"))return u?a():b.on("raphael.DOMload",a);if(c.is(a,V))return c._engine.create[D](c,a.splice(0,3+c.is(a[0],T))).add(a);var d=Array.prototype.slice.call(arguments,0);if(c.is(d[d.length-1],"function")){var e=d.pop();return u?e.call(c._engine.create[D](c,d)):b.on("raphael.DOMload",function(){e.call(c._engine.create[D](c,d))})}return c._engine.create[D](c,arguments)}function d(a){if("function"==typeof a||Object(a)!==a)return a;var b=new a.constructor;for(var c in a)a[z](c)&&(b[c]=d(a[c]));return b}function e(a,b){for(var c=0,d=a.length;d>c;c++)if(a[c]===b)return a.push(a.splice(c,1)[0])}function f(a,b,c){function d(){var f=Array.prototype.slice.call(arguments,0),g=f.join("␀"),h=d.cache=d.cache||{},i=d.count=d.count||[];return h[z](g)?(e(i,g),c?c(h[g]):h[g]):(i.length>=1e3&&delete h[i.shift()],i.push(g),h[g]=a[D](b,f),c?c(h[g]):h[g])}return d}function g(){return this.hex}function h(a,b){for(var c=[],d=0,e=a.length;e-2*!b>d;d+=2){var f=[{x:+a[d-2],y:+a[d-1]},{x:+a[d],y:+a[d+1]},{x:+a[d+2],y:+a[d+3]},{x:+a[d+4],y:+a[d+5]}];b?d?e-4==d?f[3]={x:+a[0],y:+a[1]}:e-2==d&&(f[2]={x:+a[0],y:+a[1]},f[3]={x:+a[2],y:+a[3]}):f[0]={x:+a[e-2],y:+a[e-1]}:e-4==d?f[3]=f[2]:d||(f[0]={x:+a[d],y:+a[d+1]}),c.push(["C",(-f[0].x+6*f[1].x+f[2].x)/6,(-f[0].y+6*f[1].y+f[2].y)/6,(f[1].x+6*f[2].x-f[3].x)/6,(f[1].y+6*f[2].y-f[3].y)/6,f[2].x,f[2].y])}return c}function i(a,b,c,d,e){var f=-3*b+9*c-9*d+3*e,g=a*f+6*b-12*c+6*d;return a*g-3*b+3*c}function j(a,b,c,d,e,f,g,h,j){null==j&&(j=1),j=j>1?1:0>j?0:j;for(var k=j/2,l=12,m=[-.1252,.1252,-.3678,.3678,-.5873,.5873,-.7699,.7699,-.9041,.9041,-.9816,.9816],n=[.2491,.2491,.2335,.2335,.2032,.2032,.1601,.1601,.1069,.1069,.0472,.0472],o=0,p=0;l>p;p++){var q=k*m[p]+k,r=i(q,a,c,e,g),s=i(q,b,d,f,h),t=r*r+s*s;o+=n[p]*N.sqrt(t)}return k*o}function k(a,b,c,d,e,f,g,h,i){if(!(0>i||j(a,b,c,d,e,f,g,h)<i)){var k,l=1,m=l/2,n=l-m,o=.01;for(k=j(a,b,c,d,e,f,g,h,n);Q(k-i)>o;)m/=2,n+=(i>k?1:-1)*m,k=j(a,b,c,d,e,f,g,h,n);return n}}function l(a,b,c,d,e,f,g,h){if(!(O(a,c)<P(e,g)||P(a,c)>O(e,g)||O(b,d)<P(f,h)||P(b,d)>O(f,h))){var i=(a*d-b*c)*(e-g)-(a-c)*(e*h-f*g),j=(a*d-b*c)*(f-h)-(b-d)*(e*h-f*g),k=(a-c)*(f-h)-(b-d)*(e-g);if(k){var l=i/k,m=j/k,n=+l.toFixed(2),o=+m.toFixed(2);if(!(n<+P(a,c).toFixed(2)||n>+O(a,c).toFixed(2)||n<+P(e,g).toFixed(2)||n>+O(e,g).toFixed(2)||o<+P(b,d).toFixed(2)||o>+O(b,d).toFixed(2)||o<+P(f,h).toFixed(2)||o>+O(f,h).toFixed(2)))return{x:l,y:m}}}}function m(a,b,d){var e=c.bezierBBox(a),f=c.bezierBBox(b);if(!c.isBBoxIntersect(e,f))return d?0:[];for(var g=j.apply(0,a),h=j.apply(0,b),i=O(~~(g/5),1),k=O(~~(h/5),1),m=[],n=[],o={},p=d?0:[],q=0;i+1>q;q++){var r=c.findDotsAtSegment.apply(c,a.concat(q/i));m.push({x:r.x,y:r.y,t:q/i})}for(q=0;k+1>q;q++)r=c.findDotsAtSegment.apply(c,b.concat(q/k)),n.push({x:r.x,y:r.y,t:q/k});for(q=0;i>q;q++)for(var s=0;k>s;s++){var t=m[q],u=m[q+1],v=n[s],w=n[s+1],x=Q(u.x-t.x)<.001?"y":"x",y=Q(w.x-v.x)<.001?"y":"x",z=l(t.x,t.y,u.x,u.y,v.x,v.y,w.x,w.y);if(z){if(o[z.x.toFixed(4)]==z.y.toFixed(4))continue;o[z.x.toFixed(4)]=z.y.toFixed(4);var A=t.t+Q((z[x]-t[x])/(u[x]-t[x]))*(u.t-t.t),B=v.t+Q((z[y]-v[y])/(w[y]-v[y]))*(w.t-v.t);A>=0&&1.001>=A&&B>=0&&1.001>=B&&(d?p++:p.push({x:z.x,y:z.y,t1:P(A,1),t2:P(B,1)}))}}return p}function n(a,b,d){a=c._path2curve(a),b=c._path2curve(b);for(var e,f,g,h,i,j,k,l,n,o,p=d?0:[],q=0,r=a.length;r>q;q++){var s=a[q];if("M"==s[0])e=i=s[1],f=j=s[2];else{"C"==s[0]?(n=[e,f].concat(s.slice(1)),e=n[6],f=n[7]):(n=[e,f,e,f,i,j,i,j],e=i,f=j);for(var t=0,u=b.length;u>t;t++){var v=b[t];if("M"==v[0])g=k=v[1],h=l=v[2];else{"C"==v[0]?(o=[g,h].concat(v.slice(1)),g=o[6],h=o[7]):(o=[g,h,g,h,k,l,k,l],g=k,h=l);var w=m(n,o,d);if(d)p+=w;else{for(var x=0,y=w.length;y>x;x++)w[x].segment1=q,w[x].segment2=t,w[x].bez1=n,w[x].bez2=o;p=p.concat(w)}}}}}return p}function o(a,b,c,d,e,f){null!=a?(this.a=+a,this.b=+b,this.c=+c,this.d=+d,this.e=+e,this.f=+f):(this.a=1,this.b=0,this.c=0,this.d=1,this.e=0,this.f=0)}function p(){return this.x+H+this.y+H+this.width+" × "+this.height}function q(a,b,c,d,e,f){function g(a){return((l*a+k)*a+j)*a}function h(a,b){var c=i(a,b);return((o*c+n)*c+m)*c}function i(a,b){var c,d,e,f,h,i;for(e=a,i=0;8>i;i++){if(f=g(e)-a,Q(f)<b)return e;if(h=(3*l*e+2*k)*e+j,Q(h)<1e-6)break;e-=f/h}if(c=0,d=1,e=a,c>e)return c;if(e>d)return d;for(;d>c;){if(f=g(e),Q(f-a)<b)return e;a>f?c=e:d=e,e=(d-c)/2+c}return e}var j=3*b,k=3*(d-b)-j,l=1-j-k,m=3*c,n=3*(e-c)-m,o=1-m-n;return h(a,1/(200*f))}function r(a,b){var c=[],d={};if(this.ms=b,this.times=1,a){for(var e in a)a[z](e)&&(d[_(e)]=a[e],c.push(_(e)));c.sort(lb)}this.anim=d,this.top=c[c.length-1],this.percents=c}function s(a,d,e,f,g,h){e=_(e);var i,j,k,l,m,n,p=a.ms,r={},s={},t={};if(f)for(v=0,x=ic.length;x>v;v++){var u=ic[v];if(u.el.id==d.id&&u.anim==a){u.percent!=e?(ic.splice(v,1),k=1):j=u,d.attr(u.totalOrigin);break}}else f=+s;for(var v=0,x=a.percents.length;x>v;v++){if(a.percents[v]==e||a.percents[v]>f*a.top){e=a.percents[v],m=a.percents[v-1]||0,p=p/a.top*(e-m),l=a.percents[v+1],i=a.anim[e];break}f&&d.attr(a.anim[a.percents[v]])}if(i){if(j)j.initstatus=f,j.start=new Date-j.ms*f;else{for(var y in i)if(i[z](y)&&(db[z](y)||d.paper.customAttributes[z](y)))switch(r[y]=d.attr(y),null==r[y]&&(r[y]=cb[y]),s[y]=i[y],db[y]){case T:t[y]=(s[y]-r[y])/p;break;case"colour":r[y]=c.getRGB(r[y]);var A=c.getRGB(s[y]);t[y]={r:(A.r-r[y].r)/p,g:(A.g-r[y].g)/p,b:(A.b-r[y].b)/p};break;case"path":var B=Kb(r[y],s[y]),C=B[1];for(r[y]=B[0],t[y]=[],v=0,x=r[y].length;x>v;v++){t[y][v]=[0];for(var D=1,F=r[y][v].length;F>D;D++)t[y][v][D]=(C[v][D]-r[y][v][D])/p}break;case"transform":var G=d._,H=Pb(G[y],s[y]);if(H)for(r[y]=H.from,s[y]=H.to,t[y]=[],t[y].real=!0,v=0,x=r[y].length;x>v;v++)for(t[y][v]=[r[y][v][0]],D=1,F=r[y][v].length;F>D;D++)t[y][v][D]=(s[y][v][D]-r[y][v][D])/p;else{var K=d.matrix||new o,L={_:{transform:G.transform},getBBox:function(){return d.getBBox(1)}};r[y]=[K.a,K.b,K.c,K.d,K.e,K.f],Nb(L,s[y]),s[y]=L._.transform,t[y]=[(L.matrix.a-K.a)/p,(L.matrix.b-K.b)/p,(L.matrix.c-K.c)/p,(L.matrix.d-K.d)/p,(L.matrix.e-K.e)/p,(L.matrix.f-K.f)/p]}break;case"csv":var M=I(i[y])[J](w),N=I(r[y])[J](w);if("clip-rect"==y)for(r[y]=N,t[y]=[],v=N.length;v--;)t[y][v]=(M[v]-r[y][v])/p;s[y]=M;break;default:for(M=[][E](i[y]),N=[][E](r[y]),t[y]=[],v=d.paper.customAttributes[y].length;v--;)t[y][v]=((M[v]||0)-(N[v]||0))/p}var O=i.easing,P=c.easing_formulas[O];if(!P)if(P=I(O).match(Z),P&&5==P.length){var Q=P;P=function(a){return q(a,+Q[1],+Q[2],+Q[3],+Q[4],p)}}else P=nb;if(n=i.start||a.start||+new Date,u={anim:a,percent:e,timestamp:n,start:n+(a.del||0),status:0,initstatus:f||0,stop:!1,ms:p,easing:P,from:r,diff:t,to:s,el:d,callback:i.callback,prev:m,next:l,repeat:h||a.times,origin:d.attr(),totalOrigin:g},ic.push(u),f&&!j&&!k&&(u.stop=!0,u.start=new Date-p*f,1==ic.length))return kc();k&&(u.start=new Date-u.ms*f),1==ic.length&&jc(kc)}b("raphael.anim.start."+d.id,d,a)}}function t(a){for(var b=0;b<ic.length;b++)ic[b].el.paper==a&&ic.splice(b--,1)}c.version="2.1.2",c.eve=b;var u,v,w=/[, ]+/,x={circle:1,rect:1,path:1,ellipse:1,text:1,image:1},y=/\{(\d+)\}/g,z="hasOwnProperty",A={doc:document,win:a},B={was:Object.prototype[z].call(A.win,"Raphael"),is:A.win.Raphael},C=function(){this.ca=this.customAttributes={}},D="apply",E="concat",F="ontouchstart"in A.win||A.win.DocumentTouch&&A.doc instanceof DocumentTouch,G="",H=" ",I=String,J="split",K="click dblclick mousedown mousemove mouseout mouseover mouseup touchstart touchmove touchend touchcancel"[J](H),L={mousedown:"touchstart",mousemove:"touchmove",mouseup:"touchend"},M=I.prototype.toLowerCase,N=Math,O=N.max,P=N.min,Q=N.abs,R=N.pow,S=N.PI,T="number",U="string",V="array",W=Object.prototype.toString,X=(c._ISURL=/^url\(['"]?(.+?)['"]?\)$/i,/^\s*((#[a-f\d]{6})|(#[a-f\d]{3})|rgba?\(\s*([\d\.]+%?\s*,\s*[\d\.]+%?\s*,\s*[\d\.]+%?(?:\s*,\s*[\d\.]+%?)?)\s*\)|hsba?\(\s*([\d\.]+(?:deg|\xb0|%)?\s*,\s*[\d\.]+%?\s*,\s*[\d\.]+(?:%?\s*,\s*[\d\.]+)?)%?\s*\)|hsla?\(\s*([\d\.]+(?:deg|\xb0|%)?\s*,\s*[\d\.]+%?\s*,\s*[\d\.]+(?:%?\s*,\s*[\d\.]+)?)%?\s*\))\s*$/i),Y={NaN:1,Infinity:1,"-Infinity":1},Z=/^(?:cubic-)?bezier\(([^,]+),([^,]+),([^,]+),([^\)]+)\)/,$=N.round,_=parseFloat,ab=parseInt,bb=I.prototype.toUpperCase,cb=c._availableAttrs={"arrow-end":"none","arrow-start":"none",blur:0,"clip-rect":"0 0 1e9 1e9",cursor:"default",cx:0,cy:0,fill:"#fff","fill-opacity":1,font:'10px "Arial"',"font-family":'"Arial"',"font-size":"10","font-style":"normal","font-weight":400,gradient:0,height:0,href:"http://raphaeljs.com/","letter-spacing":0,opacity:1,path:"M0,0",r:0,rx:0,ry:0,src:"",stroke:"#000","stroke-dasharray":"","stroke-linecap":"butt","stroke-linejoin":"butt","stroke-miterlimit":0,"stroke-opacity":1,"stroke-width":1,target:"_blank","text-anchor":"middle",title:"Raphael",transform:"",width:0,x:0,y:0},db=c._availableAnimAttrs={blur:T,"clip-rect":"csv",cx:T,cy:T,fill:"colour","fill-opacity":T,"font-size":T,height:T,opacity:T,path:"path",r:T,rx:T,ry:T,stroke:"colour","stroke-opacity":T,"stroke-width":T,transform:"transform",width:T,x:T,y:T},eb=/[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*/,fb={hs:1,rg:1},gb=/,?([achlmqrstvxz]),?/gi,hb=/([achlmrqstvz])[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029,]*((-?\d*\.?\d*(?:e[\-+]?\d+)?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*)+)/gi,ib=/([rstm])[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029,]*((-?\d*\.?\d*(?:e[\-+]?\d+)?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*)+)/gi,jb=/(-?\d*\.?\d*(?:e[\-+]?\d+)?)[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*/gi,kb=(c._radial_gradient=/^r(?:\(([^,]+?)[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*([^\)]+?)\))?/,{}),lb=function(a,b){return _(a)-_(b)},mb=function(){},nb=function(a){return a},ob=c._rectPath=function(a,b,c,d,e){return e?[["M",a+e,b],["l",c-2*e,0],["a",e,e,0,0,1,e,e],["l",0,d-2*e],["a",e,e,0,0,1,-e,e],["l",2*e-c,0],["a",e,e,0,0,1,-e,-e],["l",0,2*e-d],["a",e,e,0,0,1,e,-e],["z"]]:[["M",a,b],["l",c,0],["l",0,d],["l",-c,0],["z"]]},pb=function(a,b,c,d){return null==d&&(d=c),[["M",a,b],["m",0,-d],["a",c,d,0,1,1,0,2*d],["a",c,d,0,1,1,0,-2*d],["z"]]},qb=c._getPath={path:function(a){return a.attr("path")},circle:function(a){var b=a.attrs;return pb(b.cx,b.cy,b.r)},ellipse:function(a){var b=a.attrs;return pb(b.cx,b.cy,b.rx,b.ry)},rect:function(a){var b=a.attrs;return ob(b.x,b.y,b.width,b.height,b.r)},image:function(a){var b=a.attrs;return ob(b.x,b.y,b.width,b.height)},text:function(a){var b=a._getBBox();return ob(b.x,b.y,b.width,b.height)},set:function(a){var b=a._getBBox();return ob(b.x,b.y,b.width,b.height)}},rb=c.mapPath=function(a,b){if(!b)return a;var c,d,e,f,g,h,i;for(a=Kb(a),e=0,g=a.length;g>e;e++)for(i=a[e],f=1,h=i.length;h>f;f+=2)c=b.x(i[f],i[f+1]),d=b.y(i[f],i[f+1]),i[f]=c,i[f+1]=d;return a};if(c._g=A,c.type=A.win.SVGAngle||A.doc.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure","1.1")?"SVG":"VML","VML"==c.type){var sb,tb=A.doc.createElement("div");if(tb.innerHTML='<v:shape adj="1"/>',sb=tb.firstChild,sb.style.behavior="url(#default#VML)",!sb||"object"!=typeof sb.adj)return c.type=G;tb=null}c.svg=!(c.vml="VML"==c.type),c._Paper=C,c.fn=v=C.prototype=c.prototype,c._id=0,c._oid=0,c.is=function(a,b){return b=M.call(b),"finite"==b?!Y[z](+a):"array"==b?a instanceof Array:"null"==b&&null===a||b==typeof a&&null!==a||"object"==b&&a===Object(a)||"array"==b&&Array.isArray&&Array.isArray(a)||W.call(a).slice(8,-1).toLowerCase()==b},c.angle=function(a,b,d,e,f,g){if(null==f){var h=a-d,i=b-e;return h||i?(180+180*N.atan2(-i,-h)/S+360)%360:0}return c.angle(a,b,f,g)-c.angle(d,e,f,g)},c.rad=function(a){return a%360*S/180},c.deg=function(a){return 180*a/S%360},c.snapTo=function(a,b,d){if(d=c.is(d,"finite")?d:10,c.is(a,V)){for(var e=a.length;e--;)if(Q(a[e]-b)<=d)return a[e]}else{a=+a;var f=b%a;if(d>f)return b-f;if(f>a-d)return b-f+a}return b};c.createUUID=function(a,b){return function(){return"xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(a,b).toUpperCase()}}(/[xy]/g,function(a){var b=16*N.random()|0,c="x"==a?b:3&b|8;return c.toString(16)});c.setWindow=function(a){b("raphael.setWindow",c,A.win,a),A.win=a,A.doc=A.win.document,c._engine.initWin&&c._engine.initWin(A.win)};var ub=function(a){if(c.vml){var b,d=/^\s+|\s+$/g;try{var e=new ActiveXObject("htmlfile");e.write("<body>"),e.close(),b=e.body}catch(g){b=createPopup().document.body}var h=b.createTextRange();ub=f(function(a){try{b.style.color=I(a).replace(d,G);var c=h.queryCommandValue("ForeColor");return c=(255&c)<<16|65280&c|(16711680&c)>>>16,"#"+("000000"+c.toString(16)).slice(-6)}catch(e){return"none"}})}else{var i=A.doc.createElement("i");i.title="Raphaël Colour Picker",i.style.display="none",A.doc.body.appendChild(i),ub=f(function(a){return i.style.color=a,A.doc.defaultView.getComputedStyle(i,G).getPropertyValue("color")})}return ub(a)},vb=function(){return"hsb("+[this.h,this.s,this.b]+")"},wb=function(){return"hsl("+[this.h,this.s,this.l]+")"},xb=function(){return this.hex},yb=function(a,b,d){if(null==b&&c.is(a,"object")&&"r"in a&&"g"in a&&"b"in a&&(d=a.b,b=a.g,a=a.r),null==b&&c.is(a,U)){var e=c.getRGB(a);a=e.r,b=e.g,d=e.b}return(a>1||b>1||d>1)&&(a/=255,b/=255,d/=255),[a,b,d]},zb=function(a,b,d,e){a*=255,b*=255,d*=255;var f={r:a,g:b,b:d,hex:c.rgb(a,b,d),toString:xb};return c.is(e,"finite")&&(f.opacity=e),f};c.color=function(a){var b;return c.is(a,"object")&&"h"in a&&"s"in a&&"b"in a?(b=c.hsb2rgb(a),a.r=b.r,a.g=b.g,a.b=b.b,a.hex=b.hex):c.is(a,"object")&&"h"in a&&"s"in a&&"l"in a?(b=c.hsl2rgb(a),a.r=b.r,a.g=b.g,a.b=b.b,a.hex=b.hex):(c.is(a,"string")&&(a=c.getRGB(a)),c.is(a,"object")&&"r"in a&&"g"in a&&"b"in a?(b=c.rgb2hsl(a),a.h=b.h,a.s=b.s,a.l=b.l,b=c.rgb2hsb(a),a.v=b.b):(a={hex:"none"},a.r=a.g=a.b=a.h=a.s=a.v=a.l=-1)),a.toString=xb,a},c.hsb2rgb=function(a,b,c,d){this.is(a,"object")&&"h"in a&&"s"in a&&"b"in a&&(c=a.b,b=a.s,d=a.o,a=a.h),a*=360;var e,f,g,h,i;return a=a%360/60,i=c*b,h=i*(1-Q(a%2-1)),e=f=g=c-i,a=~~a,e+=[i,h,0,0,h,i][a],f+=[h,i,i,h,0,0][a],g+=[0,0,h,i,i,h][a],zb(e,f,g,d)},c.hsl2rgb=function(a,b,c,d){this.is(a,"object")&&"h"in a&&"s"in a&&"l"in a&&(c=a.l,b=a.s,a=a.h),(a>1||b>1||c>1)&&(a/=360,b/=100,c/=100),a*=360;var e,f,g,h,i;return a=a%360/60,i=2*b*(.5>c?c:1-c),h=i*(1-Q(a%2-1)),e=f=g=c-i/2,a=~~a,e+=[i,h,0,0,h,i][a],f+=[h,i,i,h,0,0][a],g+=[0,0,h,i,i,h][a],zb(e,f,g,d)},c.rgb2hsb=function(a,b,c){c=yb(a,b,c),a=c[0],b=c[1],c=c[2];var d,e,f,g;return f=O(a,b,c),g=f-P(a,b,c),d=0==g?null:f==a?(b-c)/g:f==b?(c-a)/g+2:(a-b)/g+4,d=(d+360)%6*60/360,e=0==g?0:g/f,{h:d,s:e,b:f,toString:vb}},c.rgb2hsl=function(a,b,c){c=yb(a,b,c),a=c[0],b=c[1],c=c[2];var d,e,f,g,h,i;return g=O(a,b,c),h=P(a,b,c),i=g-h,d=0==i?null:g==a?(b-c)/i:g==b?(c-a)/i+2:(a-b)/i+4,d=(d+360)%6*60/360,f=(g+h)/2,e=0==i?0:.5>f?i/(2*f):i/(2-2*f),{h:d,s:e,l:f,toString:wb}},c._path2string=function(){return this.join(",").replace(gb,"$1")};c._preload=function(a,b){var c=A.doc.createElement("img");c.style.cssText="position:absolute;left:-9999em;top:-9999em",c.onload=function(){b.call(this),this.onload=null,A.doc.body.removeChild(this)},c.onerror=function(){A.doc.body.removeChild(this)},A.doc.body.appendChild(c),c.src=a};c.getRGB=f(function(a){if(!a||(a=I(a)).indexOf("-")+1)return{r:-1,g:-1,b:-1,hex:"none",error:1,toString:g};if("none"==a)return{r:-1,g:-1,b:-1,hex:"none",toString:g};!(fb[z](a.toLowerCase().substring(0,2))||"#"==a.charAt())&&(a=ub(a));var b,d,e,f,h,i,j=a.match(X);return j?(j[2]&&(e=ab(j[2].substring(5),16),d=ab(j[2].substring(3,5),16),b=ab(j[2].substring(1,3),16)),j[3]&&(e=ab((h=j[3].charAt(3))+h,16),d=ab((h=j[3].charAt(2))+h,16),b=ab((h=j[3].charAt(1))+h,16)),j[4]&&(i=j[4][J](eb),b=_(i[0]),"%"==i[0].slice(-1)&&(b*=2.55),d=_(i[1]),"%"==i[1].slice(-1)&&(d*=2.55),e=_(i[2]),"%"==i[2].slice(-1)&&(e*=2.55),"rgba"==j[1].toLowerCase().slice(0,4)&&(f=_(i[3])),i[3]&&"%"==i[3].slice(-1)&&(f/=100)),j[5]?(i=j[5][J](eb),b=_(i[0]),"%"==i[0].slice(-1)&&(b*=2.55),d=_(i[1]),"%"==i[1].slice(-1)&&(d*=2.55),e=_(i[2]),"%"==i[2].slice(-1)&&(e*=2.55),("deg"==i[0].slice(-3)||"°"==i[0].slice(-1))&&(b/=360),"hsba"==j[1].toLowerCase().slice(0,4)&&(f=_(i[3])),i[3]&&"%"==i[3].slice(-1)&&(f/=100),c.hsb2rgb(b,d,e,f)):j[6]?(i=j[6][J](eb),b=_(i[0]),"%"==i[0].slice(-1)&&(b*=2.55),d=_(i[1]),"%"==i[1].slice(-1)&&(d*=2.55),e=_(i[2]),"%"==i[2].slice(-1)&&(e*=2.55),("deg"==i[0].slice(-3)||"°"==i[0].slice(-1))&&(b/=360),"hsla"==j[1].toLowerCase().slice(0,4)&&(f=_(i[3])),i[3]&&"%"==i[3].slice(-1)&&(f/=100),c.hsl2rgb(b,d,e,f)):(j={r:b,g:d,b:e,toString:g},j.hex="#"+(16777216|e|d<<8|b<<16).toString(16).slice(1),c.is(f,"finite")&&(j.opacity=f),j)):{r:-1,g:-1,b:-1,hex:"none",error:1,toString:g}},c),c.hsb=f(function(a,b,d){return c.hsb2rgb(a,b,d).hex}),c.hsl=f(function(a,b,d){return c.hsl2rgb(a,b,d).hex}),c.rgb=f(function(a,b,c){return"#"+(16777216|c|b<<8|a<<16).toString(16).slice(1)}),c.getColor=function(a){var b=this.getColor.start=this.getColor.start||{h:0,s:1,b:a||.75},c=this.hsb2rgb(b.h,b.s,b.b);return b.h+=.075,b.h>1&&(b.h=0,b.s-=.2,b.s<=0&&(this.getColor.start={h:0,s:1,b:b.b})),c.hex},c.getColor.reset=function(){delete this.start},c.parsePathString=function(a){if(!a)return null;var b=Ab(a);if(b.arr)return Cb(b.arr);var d={a:7,c:6,h:1,l:2,m:2,r:4,q:4,s:4,t:2,v:1,z:0},e=[];return c.is(a,V)&&c.is(a[0],V)&&(e=Cb(a)),e.length||I(a).replace(hb,function(a,b,c){var f=[],g=b.toLowerCase();if(c.replace(jb,function(a,b){b&&f.push(+b)}),"m"==g&&f.length>2&&(e.push([b][E](f.splice(0,2))),g="l",b="m"==b?"l":"L"),"r"==g)e.push([b][E](f));else for(;f.length>=d[g]&&(e.push([b][E](f.splice(0,d[g]))),d[g]););}),e.toString=c._path2string,b.arr=Cb(e),e},c.parseTransformString=f(function(a){if(!a)return null;var b=[];return c.is(a,V)&&c.is(a[0],V)&&(b=Cb(a)),b.length||I(a).replace(ib,function(a,c,d){{var e=[];M.call(c)}d.replace(jb,function(a,b){b&&e.push(+b)}),b.push([c][E](e))}),b.toString=c._path2string,b});var Ab=function(a){var b=Ab.ps=Ab.ps||{};return b[a]?b[a].sleep=100:b[a]={sleep:100},setTimeout(function(){for(var c in b)b[z](c)&&c!=a&&(b[c].sleep--,!b[c].sleep&&delete b[c])}),b[a]};c.findDotsAtSegment=function(a,b,c,d,e,f,g,h,i){var j=1-i,k=R(j,3),l=R(j,2),m=i*i,n=m*i,o=k*a+3*l*i*c+3*j*i*i*e+n*g,p=k*b+3*l*i*d+3*j*i*i*f+n*h,q=a+2*i*(c-a)+m*(e-2*c+a),r=b+2*i*(d-b)+m*(f-2*d+b),s=c+2*i*(e-c)+m*(g-2*e+c),t=d+2*i*(f-d)+m*(h-2*f+d),u=j*a+i*c,v=j*b+i*d,w=j*e+i*g,x=j*f+i*h,y=90-180*N.atan2(q-s,r-t)/S;return(q>s||t>r)&&(y+=180),{x:o,y:p,m:{x:q,y:r},n:{x:s,y:t},start:{x:u,y:v},end:{x:w,y:x},alpha:y}},c.bezierBBox=function(a,b,d,e,f,g,h,i){c.is(a,"array")||(a=[a,b,d,e,f,g,h,i]);var j=Jb.apply(null,a);return{x:j.min.x,y:j.min.y,x2:j.max.x,y2:j.max.y,width:j.max.x-j.min.x,height:j.max.y-j.min.y}},c.isPointInsideBBox=function(a,b,c){return b>=a.x&&b<=a.x2&&c>=a.y&&c<=a.y2},c.isBBoxIntersect=function(a,b){var d=c.isPointInsideBBox;return d(b,a.x,a.y)||d(b,a.x2,a.y)||d(b,a.x,a.y2)||d(b,a.x2,a.y2)||d(a,b.x,b.y)||d(a,b.x2,b.y)||d(a,b.x,b.y2)||d(a,b.x2,b.y2)||(a.x<b.x2&&a.x>b.x||b.x<a.x2&&b.x>a.x)&&(a.y<b.y2&&a.y>b.y||b.y<a.y2&&b.y>a.y)},c.pathIntersection=function(a,b){return n(a,b)},c.pathIntersectionNumber=function(a,b){return n(a,b,1)},c.isPointInsidePath=function(a,b,d){var e=c.pathBBox(a);return c.isPointInsideBBox(e,b,d)&&n(a,[["M",b,d],["H",e.x2+10]],1)%2==1},c._removedFactory=function(a){return function(){b("raphael.log",null,"Raphaël: you are calling to method “"+a+"” of removed object",a)}};var Bb=c.pathBBox=function(a){var b=Ab(a);if(b.bbox)return d(b.bbox);if(!a)return{x:0,y:0,width:0,height:0,x2:0,y2:0};a=Kb(a);for(var c,e=0,f=0,g=[],h=[],i=0,j=a.length;j>i;i++)if(c=a[i],"M"==c[0])e=c[1],f=c[2],g.push(e),h.push(f);else{var k=Jb(e,f,c[1],c[2],c[3],c[4],c[5],c[6]);g=g[E](k.min.x,k.max.x),h=h[E](k.min.y,k.max.y),e=c[5],f=c[6]}var l=P[D](0,g),m=P[D](0,h),n=O[D](0,g),o=O[D](0,h),p=n-l,q=o-m,r={x:l,y:m,x2:n,y2:o,width:p,height:q,cx:l+p/2,cy:m+q/2};return b.bbox=d(r),r},Cb=function(a){var b=d(a);return b.toString=c._path2string,b},Db=c._pathToRelative=function(a){var b=Ab(a);if(b.rel)return Cb(b.rel);c.is(a,V)&&c.is(a&&a[0],V)||(a=c.parsePathString(a));var d=[],e=0,f=0,g=0,h=0,i=0;"M"==a[0][0]&&(e=a[0][1],f=a[0][2],g=e,h=f,i++,d.push(["M",e,f]));for(var j=i,k=a.length;k>j;j++){var l=d[j]=[],m=a[j];if(m[0]!=M.call(m[0]))switch(l[0]=M.call(m[0]),l[0]){case"a":l[1]=m[1],l[2]=m[2],l[3]=m[3],l[4]=m[4],l[5]=m[5],l[6]=+(m[6]-e).toFixed(3),l[7]=+(m[7]-f).toFixed(3);break;case"v":l[1]=+(m[1]-f).toFixed(3);break;case"m":g=m[1],h=m[2];default:for(var n=1,o=m.length;o>n;n++)l[n]=+(m[n]-(n%2?e:f)).toFixed(3)}else{l=d[j]=[],"m"==m[0]&&(g=m[1]+e,h=m[2]+f);for(var p=0,q=m.length;q>p;p++)d[j][p]=m[p]}var r=d[j].length;switch(d[j][0]){case"z":e=g,f=h;break;case"h":e+=+d[j][r-1];break;case"v":f+=+d[j][r-1];break;default:e+=+d[j][r-2],f+=+d[j][r-1]}}return d.toString=c._path2string,b.rel=Cb(d),d},Eb=c._pathToAbsolute=function(a){var b=Ab(a);if(b.abs)return Cb(b.abs);if(c.is(a,V)&&c.is(a&&a[0],V)||(a=c.parsePathString(a)),!a||!a.length)return[["M",0,0]];var d=[],e=0,f=0,g=0,i=0,j=0;"M"==a[0][0]&&(e=+a[0][1],f=+a[0][2],g=e,i=f,j++,d[0]=["M",e,f]);for(var k,l,m=3==a.length&&"M"==a[0][0]&&"R"==a[1][0].toUpperCase()&&"Z"==a[2][0].toUpperCase(),n=j,o=a.length;o>n;n++){if(d.push(k=[]),l=a[n],l[0]!=bb.call(l[0]))switch(k[0]=bb.call(l[0]),k[0]){case"A":k[1]=l[1],k[2]=l[2],k[3]=l[3],k[4]=l[4],k[5]=l[5],k[6]=+(l[6]+e),k[7]=+(l[7]+f);break;case"V":k[1]=+l[1]+f;break;case"H":k[1]=+l[1]+e;break;case"R":for(var p=[e,f][E](l.slice(1)),q=2,r=p.length;r>q;q++)p[q]=+p[q]+e,p[++q]=+p[q]+f;d.pop(),d=d[E](h(p,m));break;case"M":g=+l[1]+e,i=+l[2]+f;default:for(q=1,r=l.length;r>q;q++)k[q]=+l[q]+(q%2?e:f)}else if("R"==l[0])p=[e,f][E](l.slice(1)),d.pop(),d=d[E](h(p,m)),k=["R"][E](l.slice(-2));else for(var s=0,t=l.length;t>s;s++)k[s]=l[s];switch(k[0]){case"Z":e=g,f=i;break;case"H":e=k[1];break;case"V":f=k[1];break;case"M":g=k[k.length-2],i=k[k.length-1];default:e=k[k.length-2],f=k[k.length-1]}}return d.toString=c._path2string,b.abs=Cb(d),d},Fb=function(a,b,c,d){return[a,b,c,d,c,d]},Gb=function(a,b,c,d,e,f){var g=1/3,h=2/3;return[g*a+h*c,g*b+h*d,g*e+h*c,g*f+h*d,e,f]},Hb=function(a,b,c,d,e,g,h,i,j,k){var l,m=120*S/180,n=S/180*(+e||0),o=[],p=f(function(a,b,c){var d=a*N.cos(c)-b*N.sin(c),e=a*N.sin(c)+b*N.cos(c);return{x:d,y:e}});if(k)y=k[0],z=k[1],w=k[2],x=k[3];else{l=p(a,b,-n),a=l.x,b=l.y,l=p(i,j,-n),i=l.x,j=l.y;var q=(N.cos(S/180*e),N.sin(S/180*e),(a-i)/2),r=(b-j)/2,s=q*q/(c*c)+r*r/(d*d);s>1&&(s=N.sqrt(s),c=s*c,d=s*d);var t=c*c,u=d*d,v=(g==h?-1:1)*N.sqrt(Q((t*u-t*r*r-u*q*q)/(t*r*r+u*q*q))),w=v*c*r/d+(a+i)/2,x=v*-d*q/c+(b+j)/2,y=N.asin(((b-x)/d).toFixed(9)),z=N.asin(((j-x)/d).toFixed(9));y=w>a?S-y:y,z=w>i?S-z:z,0>y&&(y=2*S+y),0>z&&(z=2*S+z),h&&y>z&&(y-=2*S),!h&&z>y&&(z-=2*S)}var A=z-y;if(Q(A)>m){var B=z,C=i,D=j;z=y+m*(h&&z>y?1:-1),i=w+c*N.cos(z),j=x+d*N.sin(z),o=Hb(i,j,c,d,e,0,h,C,D,[z,B,w,x])}A=z-y;var F=N.cos(y),G=N.sin(y),H=N.cos(z),I=N.sin(z),K=N.tan(A/4),L=4/3*c*K,M=4/3*d*K,O=[a,b],P=[a+L*G,b-M*F],R=[i+L*I,j-M*H],T=[i,j];if(P[0]=2*O[0]-P[0],P[1]=2*O[1]-P[1],k)return[P,R,T][E](o);o=[P,R,T][E](o).join()[J](",");for(var U=[],V=0,W=o.length;W>V;V++)U[V]=V%2?p(o[V-1],o[V],n).y:p(o[V],o[V+1],n).x;return U},Ib=function(a,b,c,d,e,f,g,h,i){var j=1-i;return{x:R(j,3)*a+3*R(j,2)*i*c+3*j*i*i*e+R(i,3)*g,y:R(j,3)*b+3*R(j,2)*i*d+3*j*i*i*f+R(i,3)*h}},Jb=f(function(a,b,c,d,e,f,g,h){var i,j=e-2*c+a-(g-2*e+c),k=2*(c-a)-2*(e-c),l=a-c,m=(-k+N.sqrt(k*k-4*j*l))/2/j,n=(-k-N.sqrt(k*k-4*j*l))/2/j,o=[b,h],p=[a,g];return Q(m)>"1e12"&&(m=.5),Q(n)>"1e12"&&(n=.5),m>0&&1>m&&(i=Ib(a,b,c,d,e,f,g,h,m),p.push(i.x),o.push(i.y)),n>0&&1>n&&(i=Ib(a,b,c,d,e,f,g,h,n),p.push(i.x),o.push(i.y)),j=f-2*d+b-(h-2*f+d),k=2*(d-b)-2*(f-d),l=b-d,m=(-k+N.sqrt(k*k-4*j*l))/2/j,n=(-k-N.sqrt(k*k-4*j*l))/2/j,Q(m)>"1e12"&&(m=.5),Q(n)>"1e12"&&(n=.5),m>0&&1>m&&(i=Ib(a,b,c,d,e,f,g,h,m),p.push(i.x),o.push(i.y)),n>0&&1>n&&(i=Ib(a,b,c,d,e,f,g,h,n),p.push(i.x),o.push(i.y)),{min:{x:P[D](0,p),y:P[D](0,o)},max:{x:O[D](0,p),y:O[D](0,o)}}}),Kb=c._path2curve=f(function(a,b){var c=!b&&Ab(a);if(!b&&c.curve)return Cb(c.curve);for(var d=Eb(a),e=b&&Eb(b),f={x:0,y:0,bx:0,by:0,X:0,Y:0,qx:null,qy:null},g={x:0,y:0,bx:0,by:0,X:0,Y:0,qx:null,qy:null},h=(function(a,b,c){var d,e,f={T:1,Q:1};if(!a)return["C",b.x,b.y,b.x,b.y,b.x,b.y];switch(!(a[0]in f)&&(b.qx=b.qy=null),a[0]){case"M":b.X=a[1],b.Y=a[2];break;case"A":a=["C"][E](Hb[D](0,[b.x,b.y][E](a.slice(1))));break;case"S":"C"==c||"S"==c?(d=2*b.x-b.bx,e=2*b.y-b.by):(d=b.x,e=b.y),a=["C",d,e][E](a.slice(1));break;case"T":"Q"==c||"T"==c?(b.qx=2*b.x-b.qx,b.qy=2*b.y-b.qy):(b.qx=b.x,b.qy=b.y),a=["C"][E](Gb(b.x,b.y,b.qx,b.qy,a[1],a[2]));break;case"Q":b.qx=a[1],b.qy=a[2],a=["C"][E](Gb(b.x,b.y,a[1],a[2],a[3],a[4]));break;case"L":a=["C"][E](Fb(b.x,b.y,a[1],a[2]));break;case"H":a=["C"][E](Fb(b.x,b.y,a[1],b.y));break;case"V":a=["C"][E](Fb(b.x,b.y,b.x,a[1]));break;case"Z":a=["C"][E](Fb(b.x,b.y,b.X,b.Y))}return a}),i=function(a,b){if(a[b].length>7){a[b].shift();for(var c=a[b];c.length;)k[b]="A",e&&(l[b]="A"),a.splice(b++,0,["C"][E](c.splice(0,6)));a.splice(b,1),p=O(d.length,e&&e.length||0)}},j=function(a,b,c,f,g){a&&b&&"M"==a[g][0]&&"M"!=b[g][0]&&(b.splice(g,0,["M",f.x,f.y]),c.bx=0,c.by=0,c.x=a[g][1],c.y=a[g][2],p=O(d.length,e&&e.length||0))},k=[],l=[],m="",n="",o=0,p=O(d.length,e&&e.length||0);p>o;o++){d[o]&&(m=d[o][0]),"C"!=m&&(k[o]=m,o&&(n=k[o-1])),d[o]=h(d[o],f,n),"A"!=k[o]&&"C"==m&&(k[o]="C"),i(d,o),e&&(e[o]&&(m=e[o][0]),"C"!=m&&(l[o]=m,o&&(n=l[o-1])),e[o]=h(e[o],g,n),"A"!=l[o]&&"C"==m&&(l[o]="C"),i(e,o)),j(d,e,f,g,o),j(e,d,g,f,o);var q=d[o],r=e&&e[o],s=q.length,t=e&&r.length;f.x=q[s-2],f.y=q[s-1],f.bx=_(q[s-4])||f.x,f.by=_(q[s-3])||f.y,g.bx=e&&(_(r[t-4])||g.x),g.by=e&&(_(r[t-3])||g.y),g.x=e&&r[t-2],g.y=e&&r[t-1]}return e||(c.curve=Cb(d)),e?[d,e]:d},null,Cb),Lb=(c._parseDots=f(function(a){for(var b=[],d=0,e=a.length;e>d;d++){var f={},g=a[d].match(/^([^:]*):?([\d\.]*)/);if(f.color=c.getRGB(g[1]),f.color.error)return null;f.color=f.color.hex,g[2]&&(f.offset=g[2]+"%"),b.push(f)}for(d=1,e=b.length-1;e>d;d++)if(!b[d].offset){for(var h=_(b[d-1].offset||0),i=0,j=d+1;e>j;j++)if(b[j].offset){i=b[j].offset;break}i||(i=100,j=e),i=_(i);for(var k=(i-h)/(j-d+1);j>d;d++)h+=k,b[d].offset=h+"%"}return b}),c._tear=function(a,b){a==b.top&&(b.top=a.prev),a==b.bottom&&(b.bottom=a.next),a.next&&(a.next.prev=a.prev),a.prev&&(a.prev.next=a.next)}),Mb=(c._tofront=function(a,b){b.top!==a&&(Lb(a,b),a.next=null,a.prev=b.top,b.top.next=a,b.top=a)},c._toback=function(a,b){b.bottom!==a&&(Lb(a,b),a.next=b.bottom,a.prev=null,b.bottom.prev=a,b.bottom=a)},c._insertafter=function(a,b,c){Lb(a,c),b==c.top&&(c.top=a),b.next&&(b.next.prev=a),a.next=b.next,a.prev=b,b.next=a},c._insertbefore=function(a,b,c){Lb(a,c),b==c.bottom&&(c.bottom=a),b.prev&&(b.prev.next=a),a.prev=b.prev,b.prev=a,a.next=b},c.toMatrix=function(a,b){var c=Bb(a),d={_:{transform:G},getBBox:function(){return c}};return Nb(d,b),d.matrix}),Nb=(c.transformPath=function(a,b){return rb(a,Mb(a,b))},c._extractTransform=function(a,b){if(null==b)return a._.transform;b=I(b).replace(/\.{3}|\u2026/g,a._.transform||G);var d=c.parseTransformString(b),e=0,f=0,g=0,h=1,i=1,j=a._,k=new o;if(j.transform=d||[],d)for(var l=0,m=d.length;m>l;l++){var n,p,q,r,s,t=d[l],u=t.length,v=I(t[0]).toLowerCase(),w=t[0]!=v,x=w?k.invert():0;"t"==v&&3==u?w?(n=x.x(0,0),p=x.y(0,0),q=x.x(t[1],t[2]),r=x.y(t[1],t[2]),k.translate(q-n,r-p)):k.translate(t[1],t[2]):"r"==v?2==u?(s=s||a.getBBox(1),k.rotate(t[1],s.x+s.width/2,s.y+s.height/2),e+=t[1]):4==u&&(w?(q=x.x(t[2],t[3]),r=x.y(t[2],t[3]),k.rotate(t[1],q,r)):k.rotate(t[1],t[2],t[3]),e+=t[1]):"s"==v?2==u||3==u?(s=s||a.getBBox(1),k.scale(t[1],t[u-1],s.x+s.width/2,s.y+s.height/2),h*=t[1],i*=t[u-1]):5==u&&(w?(q=x.x(t[3],t[4]),r=x.y(t[3],t[4]),k.scale(t[1],t[2],q,r)):k.scale(t[1],t[2],t[3],t[4]),h*=t[1],i*=t[2]):"m"==v&&7==u&&k.add(t[1],t[2],t[3],t[4],t[5],t[6]),j.dirtyT=1,a.matrix=k}a.matrix=k,j.sx=h,j.sy=i,j.deg=e,j.dx=f=k.e,j.dy=g=k.f,1==h&&1==i&&!e&&j.bbox?(j.bbox.x+=+f,j.bbox.y+=+g):j.dirtyT=1}),Ob=function(a){var b=a[0];switch(b.toLowerCase()){case"t":return[b,0,0];case"m":return[b,1,0,0,1,0,0];case"r":return 4==a.length?[b,0,a[2],a[3]]:[b,0];case"s":return 5==a.length?[b,1,1,a[3],a[4]]:3==a.length?[b,1,1]:[b,1]}},Pb=c._equaliseTransform=function(a,b){b=I(b).replace(/\.{3}|\u2026/g,a),a=c.parseTransformString(a)||[],b=c.parseTransformString(b)||[];
for(var d,e,f,g,h=O(a.length,b.length),i=[],j=[],k=0;h>k;k++){if(f=a[k]||Ob(b[k]),g=b[k]||Ob(f),f[0]!=g[0]||"r"==f[0].toLowerCase()&&(f[2]!=g[2]||f[3]!=g[3])||"s"==f[0].toLowerCase()&&(f[3]!=g[3]||f[4]!=g[4]))return;for(i[k]=[],j[k]=[],d=0,e=O(f.length,g.length);e>d;d++)d in f&&(i[k][d]=f[d]),d in g&&(j[k][d]=g[d])}return{from:i,to:j}};c._getContainer=function(a,b,d,e){var f;return f=null!=e||c.is(a,"object")?a:A.doc.getElementById(a),null!=f?f.tagName?null==b?{container:f,width:f.style.pixelWidth||f.offsetWidth,height:f.style.pixelHeight||f.offsetHeight}:{container:f,width:b,height:d}:{container:1,x:a,y:b,width:d,height:e}:void 0},c.pathToRelative=Db,c._engine={},c.path2curve=Kb,c.matrix=function(a,b,c,d,e,f){return new o(a,b,c,d,e,f)},function(a){function b(a){return a[0]*a[0]+a[1]*a[1]}function d(a){var c=N.sqrt(b(a));a[0]&&(a[0]/=c),a[1]&&(a[1]/=c)}a.add=function(a,b,c,d,e,f){var g,h,i,j,k=[[],[],[]],l=[[this.a,this.c,this.e],[this.b,this.d,this.f],[0,0,1]],m=[[a,c,e],[b,d,f],[0,0,1]];for(a&&a instanceof o&&(m=[[a.a,a.c,a.e],[a.b,a.d,a.f],[0,0,1]]),g=0;3>g;g++)for(h=0;3>h;h++){for(j=0,i=0;3>i;i++)j+=l[g][i]*m[i][h];k[g][h]=j}this.a=k[0][0],this.b=k[1][0],this.c=k[0][1],this.d=k[1][1],this.e=k[0][2],this.f=k[1][2]},a.invert=function(){var a=this,b=a.a*a.d-a.b*a.c;return new o(a.d/b,-a.b/b,-a.c/b,a.a/b,(a.c*a.f-a.d*a.e)/b,(a.b*a.e-a.a*a.f)/b)},a.clone=function(){return new o(this.a,this.b,this.c,this.d,this.e,this.f)},a.translate=function(a,b){this.add(1,0,0,1,a,b)},a.scale=function(a,b,c,d){null==b&&(b=a),(c||d)&&this.add(1,0,0,1,c,d),this.add(a,0,0,b,0,0),(c||d)&&this.add(1,0,0,1,-c,-d)},a.rotate=function(a,b,d){a=c.rad(a),b=b||0,d=d||0;var e=+N.cos(a).toFixed(9),f=+N.sin(a).toFixed(9);this.add(e,f,-f,e,b,d),this.add(1,0,0,1,-b,-d)},a.x=function(a,b){return a*this.a+b*this.c+this.e},a.y=function(a,b){return a*this.b+b*this.d+this.f},a.get=function(a){return+this[I.fromCharCode(97+a)].toFixed(4)},a.toString=function(){return c.svg?"matrix("+[this.get(0),this.get(1),this.get(2),this.get(3),this.get(4),this.get(5)].join()+")":[this.get(0),this.get(2),this.get(1),this.get(3),0,0].join()},a.toFilter=function(){return"progid:DXImageTransform.Microsoft.Matrix(M11="+this.get(0)+", M12="+this.get(2)+", M21="+this.get(1)+", M22="+this.get(3)+", Dx="+this.get(4)+", Dy="+this.get(5)+", sizingmethod='auto expand')"},a.offset=function(){return[this.e.toFixed(4),this.f.toFixed(4)]},a.split=function(){var a={};a.dx=this.e,a.dy=this.f;var e=[[this.a,this.c],[this.b,this.d]];a.scalex=N.sqrt(b(e[0])),d(e[0]),a.shear=e[0][0]*e[1][0]+e[0][1]*e[1][1],e[1]=[e[1][0]-e[0][0]*a.shear,e[1][1]-e[0][1]*a.shear],a.scaley=N.sqrt(b(e[1])),d(e[1]),a.shear/=a.scaley;var f=-e[0][1],g=e[1][1];return 0>g?(a.rotate=c.deg(N.acos(g)),0>f&&(a.rotate=360-a.rotate)):a.rotate=c.deg(N.asin(f)),a.isSimple=!(+a.shear.toFixed(9)||a.scalex.toFixed(9)!=a.scaley.toFixed(9)&&a.rotate),a.isSuperSimple=!+a.shear.toFixed(9)&&a.scalex.toFixed(9)==a.scaley.toFixed(9)&&!a.rotate,a.noRotation=!+a.shear.toFixed(9)&&!a.rotate,a},a.toTransformString=function(a){var b=a||this[J]();return b.isSimple?(b.scalex=+b.scalex.toFixed(4),b.scaley=+b.scaley.toFixed(4),b.rotate=+b.rotate.toFixed(4),(b.dx||b.dy?"t"+[b.dx,b.dy]:G)+(1!=b.scalex||1!=b.scaley?"s"+[b.scalex,b.scaley,0,0]:G)+(b.rotate?"r"+[b.rotate,0,0]:G)):"m"+[this.get(0),this.get(1),this.get(2),this.get(3),this.get(4),this.get(5)]}}(o.prototype);var Qb=navigator.userAgent.match(/Version\/(.*?)\s/)||navigator.userAgent.match(/Chrome\/(\d+)/);v.safari="Apple Computer, Inc."==navigator.vendor&&(Qb&&Qb[1]<4||"iP"==navigator.platform.slice(0,2))||"Google Inc."==navigator.vendor&&Qb&&Qb[1]<8?function(){var a=this.rect(-99,-99,this.width+99,this.height+99).attr({stroke:"none"});setTimeout(function(){a.remove()})}:mb;for(var Rb=function(){this.returnValue=!1},Sb=function(){return this.originalEvent.preventDefault()},Tb=function(){this.cancelBubble=!0},Ub=function(){return this.originalEvent.stopPropagation()},Vb=function(a){var b=A.doc.documentElement.scrollTop||A.doc.body.scrollTop,c=A.doc.documentElement.scrollLeft||A.doc.body.scrollLeft;return{x:a.clientX+c,y:a.clientY+b}},Wb=function(){return A.doc.addEventListener?function(a,b,c,d){var e=function(a){var b=Vb(a);return c.call(d,a,b.x,b.y)};if(a.addEventListener(b,e,!1),F&&L[b]){var f=function(b){for(var e=Vb(b),f=b,g=0,h=b.targetTouches&&b.targetTouches.length;h>g;g++)if(b.targetTouches[g].target==a){b=b.targetTouches[g],b.originalEvent=f,b.preventDefault=Sb,b.stopPropagation=Ub;break}return c.call(d,b,e.x,e.y)};a.addEventListener(L[b],f,!1)}return function(){return a.removeEventListener(b,e,!1),F&&L[b]&&a.removeEventListener(L[b],f,!1),!0}}:A.doc.attachEvent?function(a,b,c,d){var e=function(a){a=a||A.win.event;var b=A.doc.documentElement.scrollTop||A.doc.body.scrollTop,e=A.doc.documentElement.scrollLeft||A.doc.body.scrollLeft,f=a.clientX+e,g=a.clientY+b;return a.preventDefault=a.preventDefault||Rb,a.stopPropagation=a.stopPropagation||Tb,c.call(d,a,f,g)};a.attachEvent("on"+b,e);var f=function(){return a.detachEvent("on"+b,e),!0};return f}:void 0}(),Xb=[],Yb=function(a){for(var c,d=a.clientX,e=a.clientY,f=A.doc.documentElement.scrollTop||A.doc.body.scrollTop,g=A.doc.documentElement.scrollLeft||A.doc.body.scrollLeft,h=Xb.length;h--;){if(c=Xb[h],F&&a.touches){for(var i,j=a.touches.length;j--;)if(i=a.touches[j],i.identifier==c.el._drag.id){d=i.clientX,e=i.clientY,(a.originalEvent?a.originalEvent:a).preventDefault();break}}else a.preventDefault();var k,l=c.el.node,m=l.nextSibling,n=l.parentNode,o=l.style.display;A.win.opera&&n.removeChild(l),l.style.display="none",k=c.el.paper.getElementByPoint(d,e),l.style.display=o,A.win.opera&&(m?n.insertBefore(l,m):n.appendChild(l)),k&&b("raphael.drag.over."+c.el.id,c.el,k),d+=g,e+=f,b("raphael.drag.move."+c.el.id,c.move_scope||c.el,d-c.el._drag.x,e-c.el._drag.y,d,e,a)}},Zb=function(a){c.unmousemove(Yb).unmouseup(Zb);for(var d,e=Xb.length;e--;)d=Xb[e],d.el._drag={},b("raphael.drag.end."+d.el.id,d.end_scope||d.start_scope||d.move_scope||d.el,a);Xb=[]},$b=c.el={},_b=K.length;_b--;)!function(a){c[a]=$b[a]=function(b,d){return c.is(b,"function")&&(this.events=this.events||[],this.events.push({name:a,f:b,unbind:Wb(this.shape||this.node||A.doc,a,b,d||this)})),this},c["un"+a]=$b["un"+a]=function(b){for(var d=this.events||[],e=d.length;e--;)d[e].name!=a||!c.is(b,"undefined")&&d[e].f!=b||(d[e].unbind(),d.splice(e,1),!d.length&&delete this.events);return this}}(K[_b]);$b.data=function(a,d){var e=kb[this.id]=kb[this.id]||{};if(0==arguments.length)return e;if(1==arguments.length){if(c.is(a,"object")){for(var f in a)a[z](f)&&this.data(f,a[f]);return this}return b("raphael.data.get."+this.id,this,e[a],a),e[a]}return e[a]=d,b("raphael.data.set."+this.id,this,d,a),this},$b.removeData=function(a){return null==a?kb[this.id]={}:kb[this.id]&&delete kb[this.id][a],this},$b.getData=function(){return d(kb[this.id]||{})},$b.hover=function(a,b,c,d){return this.mouseover(a,c).mouseout(b,d||c)},$b.unhover=function(a,b){return this.unmouseover(a).unmouseout(b)};var ac=[];$b.drag=function(a,d,e,f,g,h){function i(i){(i.originalEvent||i).preventDefault();var j=i.clientX,k=i.clientY,l=A.doc.documentElement.scrollTop||A.doc.body.scrollTop,m=A.doc.documentElement.scrollLeft||A.doc.body.scrollLeft;if(this._drag.id=i.identifier,F&&i.touches)for(var n,o=i.touches.length;o--;)if(n=i.touches[o],this._drag.id=n.identifier,n.identifier==this._drag.id){j=n.clientX,k=n.clientY;break}this._drag.x=j+m,this._drag.y=k+l,!Xb.length&&c.mousemove(Yb).mouseup(Zb),Xb.push({el:this,move_scope:f,start_scope:g,end_scope:h}),d&&b.on("raphael.drag.start."+this.id,d),a&&b.on("raphael.drag.move."+this.id,a),e&&b.on("raphael.drag.end."+this.id,e),b("raphael.drag.start."+this.id,g||f||this,i.clientX+m,i.clientY+l,i)}return this._drag={},ac.push({el:this,start:i}),this.mousedown(i),this},$b.onDragOver=function(a){a?b.on("raphael.drag.over."+this.id,a):b.unbind("raphael.drag.over."+this.id)},$b.undrag=function(){for(var a=ac.length;a--;)ac[a].el==this&&(this.unmousedown(ac[a].start),ac.splice(a,1),b.unbind("raphael.drag.*."+this.id));!ac.length&&c.unmousemove(Yb).unmouseup(Zb),Xb=[]},v.circle=function(a,b,d){var e=c._engine.circle(this,a||0,b||0,d||0);return this.__set__&&this.__set__.push(e),e},v.rect=function(a,b,d,e,f){var g=c._engine.rect(this,a||0,b||0,d||0,e||0,f||0);return this.__set__&&this.__set__.push(g),g},v.ellipse=function(a,b,d,e){var f=c._engine.ellipse(this,a||0,b||0,d||0,e||0);return this.__set__&&this.__set__.push(f),f},v.path=function(a){a&&!c.is(a,U)&&!c.is(a[0],V)&&(a+=G);var b=c._engine.path(c.format[D](c,arguments),this);return this.__set__&&this.__set__.push(b),b},v.image=function(a,b,d,e,f){var g=c._engine.image(this,a||"about:blank",b||0,d||0,e||0,f||0);return this.__set__&&this.__set__.push(g),g},v.text=function(a,b,d){var e=c._engine.text(this,a||0,b||0,I(d));return this.__set__&&this.__set__.push(e),e},v.set=function(a){!c.is(a,"array")&&(a=Array.prototype.splice.call(arguments,0,arguments.length));var b=new mc(a);return this.__set__&&this.__set__.push(b),b.paper=this,b.type="set",b},v.setStart=function(a){this.__set__=a||this.set()},v.setFinish=function(){var a=this.__set__;return delete this.__set__,a},v.getSize=function(){var a=this.canvas.parentNode;return{width:a.offsetWidth,height:a.offsetHeight}},v.setSize=function(a,b){return c._engine.setSize.call(this,a,b)},v.setViewBox=function(a,b,d,e,f){return c._engine.setViewBox.call(this,a,b,d,e,f)},v.top=v.bottom=null,v.raphael=c;var bc=function(a){var b=a.getBoundingClientRect(),c=a.ownerDocument,d=c.body,e=c.documentElement,f=e.clientTop||d.clientTop||0,g=e.clientLeft||d.clientLeft||0,h=b.top+(A.win.pageYOffset||e.scrollTop||d.scrollTop)-f,i=b.left+(A.win.pageXOffset||e.scrollLeft||d.scrollLeft)-g;return{y:h,x:i}};v.getElementByPoint=function(a,b){var c=this,d=c.canvas,e=A.doc.elementFromPoint(a,b);if(A.win.opera&&"svg"==e.tagName){var f=bc(d),g=d.createSVGRect();g.x=a-f.x,g.y=b-f.y,g.width=g.height=1;var h=d.getIntersectionList(g,null);h.length&&(e=h[h.length-1])}if(!e)return null;for(;e.parentNode&&e!=d.parentNode&&!e.raphael;)e=e.parentNode;return e==c.canvas.parentNode&&(e=d),e=e&&e.raphael?c.getById(e.raphaelid):null},v.getElementsByBBox=function(a){var b=this.set();return this.forEach(function(d){c.isBBoxIntersect(d.getBBox(),a)&&b.push(d)}),b},v.getById=function(a){for(var b=this.bottom;b;){if(b.id==a)return b;b=b.next}return null},v.forEach=function(a,b){for(var c=this.bottom;c;){if(a.call(b,c)===!1)return this;c=c.next}return this},v.getElementsByPoint=function(a,b){var c=this.set();return this.forEach(function(d){d.isPointInside(a,b)&&c.push(d)}),c},$b.isPointInside=function(a,b){var d=this.realPath=qb[this.type](this);return this.attr("transform")&&this.attr("transform").length&&(d=c.transformPath(d,this.attr("transform"))),c.isPointInsidePath(d,a,b)},$b.getBBox=function(a){if(this.removed)return{};var b=this._;return a?((b.dirty||!b.bboxwt)&&(this.realPath=qb[this.type](this),b.bboxwt=Bb(this.realPath),b.bboxwt.toString=p,b.dirty=0),b.bboxwt):((b.dirty||b.dirtyT||!b.bbox)&&((b.dirty||!this.realPath)&&(b.bboxwt=0,this.realPath=qb[this.type](this)),b.bbox=Bb(rb(this.realPath,this.matrix)),b.bbox.toString=p,b.dirty=b.dirtyT=0),b.bbox)},$b.clone=function(){if(this.removed)return null;var a=this.paper[this.type]().attr(this.attr());return this.__set__&&this.__set__.push(a),a},$b.glow=function(a){if("text"==this.type)return null;a=a||{};var b={width:(a.width||10)+(+this.attr("stroke-width")||1),fill:a.fill||!1,opacity:a.opacity||.5,offsetx:a.offsetx||0,offsety:a.offsety||0,color:a.color||"#000"},c=b.width/2,d=this.paper,e=d.set(),f=this.realPath||qb[this.type](this);f=this.matrix?rb(f,this.matrix):f;for(var g=1;c+1>g;g++)e.push(d.path(f).attr({stroke:b.color,fill:b.fill?b.color:"none","stroke-linejoin":"round","stroke-linecap":"round","stroke-width":+(b.width/c*g).toFixed(3),opacity:+(b.opacity/c).toFixed(3)}));return e.insertBefore(this).translate(b.offsetx,b.offsety)};var cc=function(a,b,d,e,f,g,h,i,l){return null==l?j(a,b,d,e,f,g,h,i):c.findDotsAtSegment(a,b,d,e,f,g,h,i,k(a,b,d,e,f,g,h,i,l))},dc=function(a,b){return function(d,e,f){d=Kb(d);for(var g,h,i,j,k,l="",m={},n=0,o=0,p=d.length;p>o;o++){if(i=d[o],"M"==i[0])g=+i[1],h=+i[2];else{if(j=cc(g,h,i[1],i[2],i[3],i[4],i[5],i[6]),n+j>e){if(b&&!m.start){if(k=cc(g,h,i[1],i[2],i[3],i[4],i[5],i[6],e-n),l+=["C"+k.start.x,k.start.y,k.m.x,k.m.y,k.x,k.y],f)return l;m.start=l,l=["M"+k.x,k.y+"C"+k.n.x,k.n.y,k.end.x,k.end.y,i[5],i[6]].join(),n+=j,g=+i[5],h=+i[6];continue}if(!a&&!b)return k=cc(g,h,i[1],i[2],i[3],i[4],i[5],i[6],e-n),{x:k.x,y:k.y,alpha:k.alpha}}n+=j,g=+i[5],h=+i[6]}l+=i.shift()+i}return m.end=l,k=a?n:b?m:c.findDotsAtSegment(g,h,i[0],i[1],i[2],i[3],i[4],i[5],1),k.alpha&&(k={x:k.x,y:k.y,alpha:k.alpha}),k}},ec=dc(1),fc=dc(),gc=dc(0,1);c.getTotalLength=ec,c.getPointAtLength=fc,c.getSubpath=function(a,b,c){if(this.getTotalLength(a)-c<1e-6)return gc(a,b).end;var d=gc(a,c,1);return b?gc(d,b).end:d},$b.getTotalLength=function(){var a=this.getPath();if(a)return this.node.getTotalLength?this.node.getTotalLength():ec(a)},$b.getPointAtLength=function(a){var b=this.getPath();if(b)return fc(b,a)},$b.getPath=function(){var a,b=c._getPath[this.type];if("text"!=this.type&&"set"!=this.type)return b&&(a=b(this)),a},$b.getSubpath=function(a,b){var d=this.getPath();if(d)return c.getSubpath(d,a,b)};var hc=c.easing_formulas={linear:function(a){return a},"<":function(a){return R(a,1.7)},">":function(a){return R(a,.48)},"<>":function(a){var b=.48-a/1.04,c=N.sqrt(.1734+b*b),d=c-b,e=R(Q(d),1/3)*(0>d?-1:1),f=-c-b,g=R(Q(f),1/3)*(0>f?-1:1),h=e+g+.5;return 3*(1-h)*h*h+h*h*h},backIn:function(a){var b=1.70158;return a*a*((b+1)*a-b)},backOut:function(a){a-=1;var b=1.70158;return a*a*((b+1)*a+b)+1},elastic:function(a){return a==!!a?a:R(2,-10*a)*N.sin(2*(a-.075)*S/.3)+1},bounce:function(a){var b,c=7.5625,d=2.75;return 1/d>a?b=c*a*a:2/d>a?(a-=1.5/d,b=c*a*a+.75):2.5/d>a?(a-=2.25/d,b=c*a*a+.9375):(a-=2.625/d,b=c*a*a+.984375),b}};hc.easeIn=hc["ease-in"]=hc["<"],hc.easeOut=hc["ease-out"]=hc[">"],hc.easeInOut=hc["ease-in-out"]=hc["<>"],hc["back-in"]=hc.backIn,hc["back-out"]=hc.backOut;var ic=[],jc=a.requestAnimationFrame||a.webkitRequestAnimationFrame||a.mozRequestAnimationFrame||a.oRequestAnimationFrame||a.msRequestAnimationFrame||function(a){setTimeout(a,16)},kc=function(){for(var a=+new Date,d=0;d<ic.length;d++){var e=ic[d];if(!e.el.removed&&!e.paused){var f,g,h=a-e.start,i=e.ms,j=e.easing,k=e.from,l=e.diff,m=e.to,n=(e.t,e.el),o={},p={};if(e.initstatus?(h=(e.initstatus*e.anim.top-e.prev)/(e.percent-e.prev)*i,e.status=e.initstatus,delete e.initstatus,e.stop&&ic.splice(d--,1)):e.status=(e.prev+(e.percent-e.prev)*(h/i))/e.anim.top,!(0>h))if(i>h){var q=j(h/i);for(var r in k)if(k[z](r)){switch(db[r]){case T:f=+k[r]+q*i*l[r];break;case"colour":f="rgb("+[lc($(k[r].r+q*i*l[r].r)),lc($(k[r].g+q*i*l[r].g)),lc($(k[r].b+q*i*l[r].b))].join(",")+")";break;case"path":f=[];for(var t=0,u=k[r].length;u>t;t++){f[t]=[k[r][t][0]];for(var v=1,w=k[r][t].length;w>v;v++)f[t][v]=+k[r][t][v]+q*i*l[r][t][v];f[t]=f[t].join(H)}f=f.join(H);break;case"transform":if(l[r].real)for(f=[],t=0,u=k[r].length;u>t;t++)for(f[t]=[k[r][t][0]],v=1,w=k[r][t].length;w>v;v++)f[t][v]=k[r][t][v]+q*i*l[r][t][v];else{var x=function(a){return+k[r][a]+q*i*l[r][a]};f=[["m",x(0),x(1),x(2),x(3),x(4),x(5)]]}break;case"csv":if("clip-rect"==r)for(f=[],t=4;t--;)f[t]=+k[r][t]+q*i*l[r][t];break;default:var y=[][E](k[r]);for(f=[],t=n.paper.customAttributes[r].length;t--;)f[t]=+y[t]+q*i*l[r][t]}o[r]=f}n.attr(o),function(a,c,d){setTimeout(function(){b("raphael.anim.frame."+a,c,d)})}(n.id,n,e.anim)}else{if(function(a,d,e){setTimeout(function(){b("raphael.anim.frame."+d.id,d,e),b("raphael.anim.finish."+d.id,d,e),c.is(a,"function")&&a.call(d)})}(e.callback,n,e.anim),n.attr(m),ic.splice(d--,1),e.repeat>1&&!e.next){for(g in m)m[z](g)&&(p[g]=e.totalOrigin[g]);e.el.attr(p),s(e.anim,e.el,e.anim.percents[0],null,e.totalOrigin,e.repeat-1)}e.next&&!e.stop&&s(e.anim,e.el,e.next,null,e.totalOrigin,e.repeat)}}}c.svg&&n&&n.paper&&n.paper.safari(),ic.length&&jc(kc)},lc=function(a){return a>255?255:0>a?0:a};$b.animateWith=function(a,b,d,e,f,g){var h=this;if(h.removed)return g&&g.call(h),h;var i=d instanceof r?d:c.animation(d,e,f,g);s(i,h,i.percents[0],null,h.attr());for(var j=0,k=ic.length;k>j;j++)if(ic[j].anim==b&&ic[j].el==a){ic[k-1].start=ic[j].start;break}return h},$b.onAnimation=function(a){return a?b.on("raphael.anim.frame."+this.id,a):b.unbind("raphael.anim.frame."+this.id),this},r.prototype.delay=function(a){var b=new r(this.anim,this.ms);return b.times=this.times,b.del=+a||0,b},r.prototype.repeat=function(a){var b=new r(this.anim,this.ms);return b.del=this.del,b.times=N.floor(O(a,0))||1,b},c.animation=function(a,b,d,e){if(a instanceof r)return a;(c.is(d,"function")||!d)&&(e=e||d||null,d=null),a=Object(a),b=+b||0;var f,g,h={};for(g in a)a[z](g)&&_(g)!=g&&_(g)+"%"!=g&&(f=!0,h[g]=a[g]);if(f)return d&&(h.easing=d),e&&(h.callback=e),new r({100:h},b);if(e){var i=0;for(var j in a){var k=ab(j);a[z](j)&&k>i&&(i=k)}i+="%",!a[i].callback&&(a[i].callback=e)}return new r(a,b)},$b.animate=function(a,b,d,e){var f=this;if(f.removed)return e&&e.call(f),f;var g=a instanceof r?a:c.animation(a,b,d,e);return s(g,f,g.percents[0],null,f.attr()),f},$b.setTime=function(a,b){return a&&null!=b&&this.status(a,P(b,a.ms)/a.ms),this},$b.status=function(a,b){var c,d,e=[],f=0;if(null!=b)return s(a,this,-1,P(b,1)),this;for(c=ic.length;c>f;f++)if(d=ic[f],d.el.id==this.id&&(!a||d.anim==a)){if(a)return d.status;e.push({anim:d.anim,status:d.status})}return a?0:e},$b.pause=function(a){for(var c=0;c<ic.length;c++)ic[c].el.id!=this.id||a&&ic[c].anim!=a||b("raphael.anim.pause."+this.id,this,ic[c].anim)!==!1&&(ic[c].paused=!0);return this},$b.resume=function(a){for(var c=0;c<ic.length;c++)if(ic[c].el.id==this.id&&(!a||ic[c].anim==a)){var d=ic[c];b("raphael.anim.resume."+this.id,this,d.anim)!==!1&&(delete d.paused,this.status(d.anim,d.status))}return this},$b.stop=function(a){for(var c=0;c<ic.length;c++)ic[c].el.id!=this.id||a&&ic[c].anim!=a||b("raphael.anim.stop."+this.id,this,ic[c].anim)!==!1&&ic.splice(c--,1);return this},b.on("raphael.remove",t),b.on("raphael.clear",t),$b.toString=function(){return"Raphaël’s object"};var mc=function(a){if(this.items=[],this.length=0,this.type="set",a)for(var b=0,c=a.length;c>b;b++)!a[b]||a[b].constructor!=$b.constructor&&a[b].constructor!=mc||(this[this.items.length]=this.items[this.items.length]=a[b],this.length++)},nc=mc.prototype;nc.push=function(){for(var a,b,c=0,d=arguments.length;d>c;c++)a=arguments[c],!a||a.constructor!=$b.constructor&&a.constructor!=mc||(b=this.items.length,this[b]=this.items[b]=a,this.length++);return this},nc.pop=function(){return this.length&&delete this[this.length--],this.items.pop()},nc.forEach=function(a,b){for(var c=0,d=this.items.length;d>c;c++)if(a.call(b,this.items[c],c)===!1)return this;return this};for(var oc in $b)$b[z](oc)&&(nc[oc]=function(a){return function(){var b=arguments;return this.forEach(function(c){c[a][D](c,b)})}}(oc));return nc.attr=function(a,b){if(a&&c.is(a,V)&&c.is(a[0],"object"))for(var d=0,e=a.length;e>d;d++)this.items[d].attr(a[d]);else for(var f=0,g=this.items.length;g>f;f++)this.items[f].attr(a,b);return this},nc.clear=function(){for(;this.length;)this.pop()},nc.splice=function(a,b){a=0>a?O(this.length+a,0):a,b=O(0,P(this.length-a,b));var c,d=[],e=[],f=[];for(c=2;c<arguments.length;c++)f.push(arguments[c]);for(c=0;b>c;c++)e.push(this[a+c]);for(;c<this.length-a;c++)d.push(this[a+c]);var g=f.length;for(c=0;c<g+d.length;c++)this.items[a+c]=this[a+c]=g>c?f[c]:d[c-g];for(c=this.items.length=this.length-=b-g;this[c];)delete this[c++];return new mc(e)},nc.exclude=function(a){for(var b=0,c=this.length;c>b;b++)if(this[b]==a)return this.splice(b,1),!0},nc.animate=function(a,b,d,e){(c.is(d,"function")||!d)&&(e=d||null);var f,g,h=this.items.length,i=h,j=this;if(!h)return this;e&&(g=function(){!--h&&e.call(j)}),d=c.is(d,U)?d:g;var k=c.animation(a,b,d,g);for(f=this.items[--i].animate(k);i--;)this.items[i]&&!this.items[i].removed&&this.items[i].animateWith(f,k,k),this.items[i]&&!this.items[i].removed||h--;return this},nc.insertAfter=function(a){for(var b=this.items.length;b--;)this.items[b].insertAfter(a);return this},nc.getBBox=function(){for(var a=[],b=[],c=[],d=[],e=this.items.length;e--;)if(!this.items[e].removed){var f=this.items[e].getBBox();a.push(f.x),b.push(f.y),c.push(f.x+f.width),d.push(f.y+f.height)}return a=P[D](0,a),b=P[D](0,b),c=O[D](0,c),d=O[D](0,d),{x:a,y:b,x2:c,y2:d,width:c-a,height:d-b}},nc.clone=function(a){a=this.paper.set();for(var b=0,c=this.items.length;c>b;b++)a.push(this.items[b].clone());return a},nc.toString=function(){return"Raphaël‘s set"},nc.glow=function(a){var b=this.paper.set();return this.forEach(function(c){var d=c.glow(a);null!=d&&d.forEach(function(a){b.push(a)})}),b},nc.isPointInside=function(a,b){var c=!1;return this.forEach(function(d){return d.isPointInside(a,b)?(c=!0,!1):void 0}),c},c.registerFont=function(a){if(!a.face)return a;this.fonts=this.fonts||{};var b={w:a.w,face:{},glyphs:{}},c=a.face["font-family"];for(var d in a.face)a.face[z](d)&&(b.face[d]=a.face[d]);if(this.fonts[c]?this.fonts[c].push(b):this.fonts[c]=[b],!a.svg){b.face["units-per-em"]=ab(a.face["units-per-em"],10);for(var e in a.glyphs)if(a.glyphs[z](e)){var f=a.glyphs[e];if(b.glyphs[e]={w:f.w,k:{},d:f.d&&"M"+f.d.replace(/[mlcxtrv]/g,function(a){return{l:"L",c:"C",x:"z",t:"m",r:"l",v:"c"}[a]||"M"})+"z"},f.k)for(var g in f.k)f[z](g)&&(b.glyphs[e].k[g]=f.k[g])}}return a},v.getFont=function(a,b,d,e){if(e=e||"normal",d=d||"normal",b=+b||{normal:400,bold:700,lighter:300,bolder:800}[b]||400,c.fonts){var f=c.fonts[a];if(!f){var g=new RegExp("(^|\\s)"+a.replace(/[^\w\d\s+!~.:_-]/g,G)+"(\\s|$)","i");for(var h in c.fonts)if(c.fonts[z](h)&&g.test(h)){f=c.fonts[h];break}}var i;if(f)for(var j=0,k=f.length;k>j&&(i=f[j],i.face["font-weight"]!=b||i.face["font-style"]!=d&&i.face["font-style"]||i.face["font-stretch"]!=e);j++);return i}},v.print=function(a,b,d,e,f,g,h,i){g=g||"middle",h=O(P(h||0,1),-1),i=O(P(i||1,3),1);var j,k=I(d)[J](G),l=0,m=0,n=G;if(c.is(e,"string")&&(e=this.getFont(e)),e){j=(f||16)/e.face["units-per-em"];for(var o=e.face.bbox[J](w),p=+o[0],q=o[3]-o[1],r=0,s=+o[1]+("baseline"==g?q+ +e.face.descent:q/2),t=0,u=k.length;u>t;t++){if("\n"==k[t])l=0,x=0,m=0,r+=q*i;else{var v=m&&e.glyphs[k[t-1]]||{},x=e.glyphs[k[t]];l+=m?(v.w||e.w)+(v.k&&v.k[k[t]]||0)+e.w*h:0,m=1}x&&x.d&&(n+=c.transformPath(x.d,["t",l*j,r*j,"s",j,j,p,s,"t",(a-p)/j,(b-s)/j]))}}return this.path(n).attr({fill:"#000",stroke:"none"})},v.add=function(a){if(c.is(a,"array"))for(var b,d=this.set(),e=0,f=a.length;f>e;e++)b=a[e]||{},x[z](b.type)&&d.push(this[b.type]().attr(b));return d},c.format=function(a,b){var d=c.is(b,V)?[0][E](b):arguments;return a&&c.is(a,U)&&d.length-1&&(a=a.replace(y,function(a,b){return null==d[++b]?G:d[b]})),a||G},c.fullfill=function(){var a=/\{([^\}]+)\}/g,b=/(?:(?:^|\.)(.+?)(?=\[|\.|$|\()|\[('|")(.+?)\2\])(\(\))?/g,c=function(a,c,d){var e=d;return c.replace(b,function(a,b,c,d,f){b=b||d,e&&(b in e&&(e=e[b]),"function"==typeof e&&f&&(e=e()))}),e=(null==e||e==d?a:e)+""};return function(b,d){return String(b).replace(a,function(a,b){return c(a,b,d)})}}(),c.ninja=function(){return B.was?A.win.Raphael=B.is:delete Raphael,c},c.st=nc,b.on("raphael.DOMload",function(){u=!0}),function(a,b,d){function e(){/in/.test(a.readyState)?setTimeout(e,9):c.eve("raphael.DOMload")}null==a.readyState&&a.addEventListener&&(a.addEventListener(b,d=function(){a.removeEventListener(b,d,!1),a.readyState="complete"},!1),a.readyState="loading"),e()}(document,"DOMContentLoaded"),function(){if(c.svg){var a="hasOwnProperty",b=String,d=parseFloat,e=parseInt,f=Math,g=f.max,h=f.abs,i=f.pow,j=/[, ]+/,k=c.eve,l="",m=" ",n="http://www.w3.org/1999/xlink",o={block:"M5,0 0,2.5 5,5z",classic:"M5,0 0,2.5 5,5 3.5,3 3.5,2z",diamond:"M2.5,0 5,2.5 2.5,5 0,2.5z",open:"M6,1 1,3.5 6,6",oval:"M2.5,0A2.5,2.5,0,0,1,2.5,5 2.5,2.5,0,0,1,2.5,0z"},p={};c.toString=function(){return"Your browser supports SVG.\nYou are running Raphaël "+this.version};var q=function(d,e){if(e){"string"==typeof d&&(d=q(d));for(var f in e)e[a](f)&&("xlink:"==f.substring(0,6)?d.setAttributeNS(n,f.substring(6),b(e[f])):d.setAttribute(f,b(e[f])))}else d=c._g.doc.createElementNS("http://www.w3.org/2000/svg",d),d.style&&(d.style.webkitTapHighlightColor="rgba(0,0,0,0)");return d},r=function(a,e){var j="linear",k=a.id+e,m=.5,n=.5,o=a.node,p=a.paper,r=o.style,s=c._g.doc.getElementById(k);if(!s){if(e=b(e).replace(c._radial_gradient,function(a,b,c){if(j="radial",b&&c){m=d(b),n=d(c);var e=2*(n>.5)-1;i(m-.5,2)+i(n-.5,2)>.25&&(n=f.sqrt(.25-i(m-.5,2))*e+.5)&&.5!=n&&(n=n.toFixed(5)-1e-5*e)}return l}),e=e.split(/\s*\-\s*/),"linear"==j){var t=e.shift();if(t=-d(t),isNaN(t))return null;var u=[0,0,f.cos(c.rad(t)),f.sin(c.rad(t))],v=1/(g(h(u[2]),h(u[3]))||1);u[2]*=v,u[3]*=v,u[2]<0&&(u[0]=-u[2],u[2]=0),u[3]<0&&(u[1]=-u[3],u[3]=0)}var w=c._parseDots(e);if(!w)return null;if(k=k.replace(/[\(\)\s,\xb0#]/g,"_"),a.gradient&&k!=a.gradient.id&&(p.defs.removeChild(a.gradient),delete a.gradient),!a.gradient){s=q(j+"Gradient",{id:k}),a.gradient=s,q(s,"radial"==j?{fx:m,fy:n}:{x1:u[0],y1:u[1],x2:u[2],y2:u[3],gradientTransform:a.matrix.invert()}),p.defs.appendChild(s);for(var x=0,y=w.length;y>x;x++)s.appendChild(q("stop",{offset:w[x].offset?w[x].offset:x?"100%":"0%","stop-color":w[x].color||"#fff"}))}}return q(o,{fill:"url("+document.location+"#"+k+")",opacity:1,"fill-opacity":1}),r.fill=l,r.opacity=1,r.fillOpacity=1,1},s=function(a){var b=a.getBBox(1);q(a.pattern,{patternTransform:a.matrix.invert()+" translate("+b.x+","+b.y+")"})},t=function(d,e,f){if("path"==d.type){for(var g,h,i,j,k,m=b(e).toLowerCase().split("-"),n=d.paper,r=f?"end":"start",s=d.node,t=d.attrs,u=t["stroke-width"],v=m.length,w="classic",x=3,y=3,z=5;v--;)switch(m[v]){case"block":case"classic":case"oval":case"diamond":case"open":case"none":w=m[v];break;case"wide":y=5;break;case"narrow":y=2;break;case"long":x=5;break;case"short":x=2}if("open"==w?(x+=2,y+=2,z+=2,i=1,j=f?4:1,k={fill:"none",stroke:t.stroke}):(j=i=x/2,k={fill:t.stroke,stroke:"none"}),d._.arrows?f?(d._.arrows.endPath&&p[d._.arrows.endPath]--,d._.arrows.endMarker&&p[d._.arrows.endMarker]--):(d._.arrows.startPath&&p[d._.arrows.startPath]--,d._.arrows.startMarker&&p[d._.arrows.startMarker]--):d._.arrows={},"none"!=w){var A="raphael-marker-"+w,B="raphael-marker-"+r+w+x+y+"-obj"+d.id;c._g.doc.getElementById(A)?p[A]++:(n.defs.appendChild(q(q("path"),{"stroke-linecap":"round",d:o[w],id:A})),p[A]=1);var C,D=c._g.doc.getElementById(B);D?(p[B]++,C=D.getElementsByTagName("use")[0]):(D=q(q("marker"),{id:B,markerHeight:y,markerWidth:x,orient:"auto",refX:j,refY:y/2}),C=q(q("use"),{"xlink:href":"#"+A,transform:(f?"rotate(180 "+x/2+" "+y/2+") ":l)+"scale("+x/z+","+y/z+")","stroke-width":(1/((x/z+y/z)/2)).toFixed(4)}),D.appendChild(C),n.defs.appendChild(D),p[B]=1),q(C,k);var E=i*("diamond"!=w&&"oval"!=w);f?(g=d._.arrows.startdx*u||0,h=c.getTotalLength(t.path)-E*u):(g=E*u,h=c.getTotalLength(t.path)-(d._.arrows.enddx*u||0)),k={},k["marker-"+r]="url(#"+B+")",(h||g)&&(k.d=c.getSubpath(t.path,g,h)),q(s,k),d._.arrows[r+"Path"]=A,d._.arrows[r+"Marker"]=B,d._.arrows[r+"dx"]=E,d._.arrows[r+"Type"]=w,d._.arrows[r+"String"]=e}else f?(g=d._.arrows.startdx*u||0,h=c.getTotalLength(t.path)-g):(g=0,h=c.getTotalLength(t.path)-(d._.arrows.enddx*u||0)),d._.arrows[r+"Path"]&&q(s,{d:c.getSubpath(t.path,g,h)}),delete d._.arrows[r+"Path"],delete d._.arrows[r+"Marker"],delete d._.arrows[r+"dx"],delete d._.arrows[r+"Type"],delete d._.arrows[r+"String"];for(k in p)if(p[a](k)&&!p[k]){var F=c._g.doc.getElementById(k);F&&F.parentNode.removeChild(F)}}},u={"":[0],none:[0],"-":[3,1],".":[1,1],"-.":[3,1,1,1],"-..":[3,1,1,1,1,1],". ":[1,3],"- ":[4,3],"--":[8,3],"- .":[4,3,1,3],"--.":[8,3,1,3],"--..":[8,3,1,3,1,3]},v=function(a,c,d){if(c=u[b(c).toLowerCase()]){for(var e=a.attrs["stroke-width"]||"1",f={round:e,square:e,butt:0}[a.attrs["stroke-linecap"]||d["stroke-linecap"]]||0,g=[],h=c.length;h--;)g[h]=c[h]*e+(h%2?1:-1)*f;q(a.node,{"stroke-dasharray":g.join(",")})}},w=function(d,f){var i=d.node,k=d.attrs,m=i.style.visibility;i.style.visibility="hidden";for(var o in f)if(f[a](o)){if(!c._availableAttrs[a](o))continue;var p=f[o];switch(k[o]=p,o){case"blur":d.blur(p);break;case"title":var u=i.getElementsByTagName("title");if(u.length&&(u=u[0]))u.firstChild.nodeValue=p;else{u=q("title");var w=c._g.doc.createTextNode(p);u.appendChild(w),i.appendChild(u)}break;case"href":case"target":var x=i.parentNode;if("a"!=x.tagName.toLowerCase()){var z=q("a");x.insertBefore(z,i),z.appendChild(i),x=z}"target"==o?x.setAttributeNS(n,"show","blank"==p?"new":p):x.setAttributeNS(n,o,p);break;case"cursor":i.style.cursor=p;break;case"transform":d.transform(p);break;case"arrow-start":t(d,p);break;case"arrow-end":t(d,p,1);break;case"clip-rect":var A=b(p).split(j);if(4==A.length){d.clip&&d.clip.parentNode.parentNode.removeChild(d.clip.parentNode);var B=q("clipPath"),C=q("rect");B.id=c.createUUID(),q(C,{x:A[0],y:A[1],width:A[2],height:A[3]}),B.appendChild(C),d.paper.defs.appendChild(B),q(i,{"clip-path":"url(#"+B.id+")"}),d.clip=C}if(!p){var D=i.getAttribute("clip-path");if(D){var E=c._g.doc.getElementById(D.replace(/(^url\(#|\)$)/g,l));E&&E.parentNode.removeChild(E),q(i,{"clip-path":l}),delete d.clip}}break;case"path":"path"==d.type&&(q(i,{d:p?k.path=c._pathToAbsolute(p):"M0,0"}),d._.dirty=1,d._.arrows&&("startString"in d._.arrows&&t(d,d._.arrows.startString),"endString"in d._.arrows&&t(d,d._.arrows.endString,1)));break;case"width":if(i.setAttribute(o,p),d._.dirty=1,!k.fx)break;o="x",p=k.x;case"x":k.fx&&(p=-k.x-(k.width||0));case"rx":if("rx"==o&&"rect"==d.type)break;case"cx":i.setAttribute(o,p),d.pattern&&s(d),d._.dirty=1;break;case"height":if(i.setAttribute(o,p),d._.dirty=1,!k.fy)break;o="y",p=k.y;case"y":k.fy&&(p=-k.y-(k.height||0));case"ry":if("ry"==o&&"rect"==d.type)break;case"cy":i.setAttribute(o,p),d.pattern&&s(d),d._.dirty=1;break;case"r":"rect"==d.type?q(i,{rx:p,ry:p}):i.setAttribute(o,p),d._.dirty=1;break;case"src":"image"==d.type&&i.setAttributeNS(n,"href",p);break;case"stroke-width":(1!=d._.sx||1!=d._.sy)&&(p/=g(h(d._.sx),h(d._.sy))||1),i.setAttribute(o,p),k["stroke-dasharray"]&&v(d,k["stroke-dasharray"],f),d._.arrows&&("startString"in d._.arrows&&t(d,d._.arrows.startString),"endString"in d._.arrows&&t(d,d._.arrows.endString,1));break;case"stroke-dasharray":v(d,p,f);break;case"fill":var F=b(p).match(c._ISURL);if(F){B=q("pattern");var G=q("image");B.id=c.createUUID(),q(B,{x:0,y:0,patternUnits:"userSpaceOnUse",height:1,width:1}),q(G,{x:0,y:0,"xlink:href":F[1]}),B.appendChild(G),function(a){c._preload(F[1],function(){var b=this.offsetWidth,c=this.offsetHeight;q(a,{width:b,height:c}),q(G,{width:b,height:c}),d.paper.safari()})}(B),d.paper.defs.appendChild(B),q(i,{fill:"url(#"+B.id+")"}),d.pattern=B,d.pattern&&s(d);break}var H=c.getRGB(p);if(H.error){if(("circle"==d.type||"ellipse"==d.type||"r"!=b(p).charAt())&&r(d,p)){if("opacity"in k||"fill-opacity"in k){var I=c._g.doc.getElementById(i.getAttribute("fill").replace(/^url\(#|\)$/g,l));if(I){var J=I.getElementsByTagName("stop");q(J[J.length-1],{"stop-opacity":("opacity"in k?k.opacity:1)*("fill-opacity"in k?k["fill-opacity"]:1)})}}k.gradient=p,k.fill="none";break}}else delete f.gradient,delete k.gradient,!c.is(k.opacity,"undefined")&&c.is(f.opacity,"undefined")&&q(i,{opacity:k.opacity}),!c.is(k["fill-opacity"],"undefined")&&c.is(f["fill-opacity"],"undefined")&&q(i,{"fill-opacity":k["fill-opacity"]});H[a]("opacity")&&q(i,{"fill-opacity":H.opacity>1?H.opacity/100:H.opacity});case"stroke":H=c.getRGB(p),i.setAttribute(o,H.hex),"stroke"==o&&H[a]("opacity")&&q(i,{"stroke-opacity":H.opacity>1?H.opacity/100:H.opacity}),"stroke"==o&&d._.arrows&&("startString"in d._.arrows&&t(d,d._.arrows.startString),"endString"in d._.arrows&&t(d,d._.arrows.endString,1));break;case"gradient":("circle"==d.type||"ellipse"==d.type||"r"!=b(p).charAt())&&r(d,p);break;
case"opacity":k.gradient&&!k[a]("stroke-opacity")&&q(i,{"stroke-opacity":p>1?p/100:p});case"fill-opacity":if(k.gradient){I=c._g.doc.getElementById(i.getAttribute("fill").replace(/^url\(#|\)$/g,l)),I&&(J=I.getElementsByTagName("stop"),q(J[J.length-1],{"stop-opacity":p}));break}default:"font-size"==o&&(p=e(p,10)+"px");var K=o.replace(/(\-.)/g,function(a){return a.substring(1).toUpperCase()});i.style[K]=p,d._.dirty=1,i.setAttribute(o,p)}}y(d,f),i.style.visibility=m},x=1.2,y=function(d,f){if("text"==d.type&&(f[a]("text")||f[a]("font")||f[a]("font-size")||f[a]("x")||f[a]("y"))){var g=d.attrs,h=d.node,i=h.firstChild?e(c._g.doc.defaultView.getComputedStyle(h.firstChild,l).getPropertyValue("font-size"),10):10;if(f[a]("text")){for(g.text=f.text;h.firstChild;)h.removeChild(h.firstChild);for(var j,k=b(f.text).split("\n"),m=[],n=0,o=k.length;o>n;n++)j=q("tspan"),n&&q(j,{dy:i*x,x:g.x}),j.appendChild(c._g.doc.createTextNode(k[n])),h.appendChild(j),m[n]=j}else for(m=h.getElementsByTagName("tspan"),n=0,o=m.length;o>n;n++)n?q(m[n],{dy:i*x,x:g.x}):q(m[0],{dy:0});q(h,{x:g.x,y:g.y}),d._.dirty=1;var p=d._getBBox(),r=g.y-(p.y+p.height/2);r&&c.is(r,"finite")&&q(m[0],{dy:r})}},z=function(a){return a.parentNode&&"a"===a.parentNode.tagName.toLowerCase()?a.parentNode:a},A=function(a,b){this[0]=this.node=a,a.raphael=!0,this.id=c._oid++,a.raphaelid=this.id,this.matrix=c.matrix(),this.realPath=null,this.paper=b,this.attrs=this.attrs||{},this._={transform:[],sx:1,sy:1,deg:0,dx:0,dy:0,dirty:1},!b.bottom&&(b.bottom=this),this.prev=b.top,b.top&&(b.top.next=this),b.top=this,this.next=null},B=c.el;A.prototype=B,B.constructor=A,c._engine.path=function(a,b){var c=q("path");b.canvas&&b.canvas.appendChild(c);var d=new A(c,b);return d.type="path",w(d,{fill:"none",stroke:"#000",path:a}),d},B.rotate=function(a,c,e){if(this.removed)return this;if(a=b(a).split(j),a.length-1&&(c=d(a[1]),e=d(a[2])),a=d(a[0]),null==e&&(c=e),null==c||null==e){var f=this.getBBox(1);c=f.x+f.width/2,e=f.y+f.height/2}return this.transform(this._.transform.concat([["r",a,c,e]])),this},B.scale=function(a,c,e,f){if(this.removed)return this;if(a=b(a).split(j),a.length-1&&(c=d(a[1]),e=d(a[2]),f=d(a[3])),a=d(a[0]),null==c&&(c=a),null==f&&(e=f),null==e||null==f)var g=this.getBBox(1);return e=null==e?g.x+g.width/2:e,f=null==f?g.y+g.height/2:f,this.transform(this._.transform.concat([["s",a,c,e,f]])),this},B.translate=function(a,c){return this.removed?this:(a=b(a).split(j),a.length-1&&(c=d(a[1])),a=d(a[0])||0,c=+c||0,this.transform(this._.transform.concat([["t",a,c]])),this)},B.transform=function(b){var d=this._;if(null==b)return d.transform;if(c._extractTransform(this,b),this.clip&&q(this.clip,{transform:this.matrix.invert()}),this.pattern&&s(this),this.node&&q(this.node,{transform:this.matrix}),1!=d.sx||1!=d.sy){var e=this.attrs[a]("stroke-width")?this.attrs["stroke-width"]:1;this.attr({"stroke-width":e})}return this},B.hide=function(){return!this.removed&&this.paper.safari(this.node.style.display="none"),this},B.show=function(){return!this.removed&&this.paper.safari(this.node.style.display=""),this},B.remove=function(){var a=z(this.node);if(!this.removed&&a.parentNode){var b=this.paper;b.__set__&&b.__set__.exclude(this),k.unbind("raphael.*.*."+this.id),this.gradient&&b.defs.removeChild(this.gradient),c._tear(this,b),a.parentNode.removeChild(a),this.removeData();for(var d in this)this[d]="function"==typeof this[d]?c._removedFactory(d):null;this.removed=!0}},B._getBBox=function(){if("none"==this.node.style.display){this.show();var a=!0}var b,c=!1;this.paper.canvas.parentElement?b=this.paper.canvas.parentElement.style:this.paper.canvas.parentNode&&(b=this.paper.canvas.parentNode.style),b&&"none"==b.display&&(c=!0,b.display="");var d={};try{d=this.node.getBBox()}catch(e){d={x:this.node.clientLeft,y:this.node.clientTop,width:this.node.clientWidth,height:this.node.clientHeight}}finally{d=d||{},c&&(b.display="none")}return a&&this.hide(),d},B.attr=function(b,d){if(this.removed)return this;if(null==b){var e={};for(var f in this.attrs)this.attrs[a](f)&&(e[f]=this.attrs[f]);return e.gradient&&"none"==e.fill&&(e.fill=e.gradient)&&delete e.gradient,e.transform=this._.transform,e}if(null==d&&c.is(b,"string")){if("fill"==b&&"none"==this.attrs.fill&&this.attrs.gradient)return this.attrs.gradient;if("transform"==b)return this._.transform;for(var g=b.split(j),h={},i=0,l=g.length;l>i;i++)b=g[i],h[b]=b in this.attrs?this.attrs[b]:c.is(this.paper.customAttributes[b],"function")?this.paper.customAttributes[b].def:c._availableAttrs[b];return l-1?h:h[g[0]]}if(null==d&&c.is(b,"array")){for(h={},i=0,l=b.length;l>i;i++)h[b[i]]=this.attr(b[i]);return h}if(null!=d){var m={};m[b]=d}else null!=b&&c.is(b,"object")&&(m=b);for(var n in m)k("raphael.attr."+n+"."+this.id,this,m[n]);for(n in this.paper.customAttributes)if(this.paper.customAttributes[a](n)&&m[a](n)&&c.is(this.paper.customAttributes[n],"function")){var o=this.paper.customAttributes[n].apply(this,[].concat(m[n]));this.attrs[n]=m[n];for(var p in o)o[a](p)&&(m[p]=o[p])}return w(this,m),this},B.toFront=function(){if(this.removed)return this;var a=z(this.node);a.parentNode.appendChild(a);var b=this.paper;return b.top!=this&&c._tofront(this,b),this},B.toBack=function(){if(this.removed)return this;var a=z(this.node),b=a.parentNode;b.insertBefore(a,b.firstChild),c._toback(this,this.paper);this.paper;return this},B.insertAfter=function(a){if(this.removed||!a)return this;var b=z(this.node),d=z(a.node||a[a.length-1].node);return d.nextSibling?d.parentNode.insertBefore(b,d.nextSibling):d.parentNode.appendChild(b),c._insertafter(this,a,this.paper),this},B.insertBefore=function(a){if(this.removed||!a)return this;var b=z(this.node),d=z(a.node||a[0].node);return d.parentNode.insertBefore(b,d),c._insertbefore(this,a,this.paper),this},B.blur=function(a){var b=this;if(0!==+a){var d=q("filter"),e=q("feGaussianBlur");b.attrs.blur=a,d.id=c.createUUID(),q(e,{stdDeviation:+a||1.5}),d.appendChild(e),b.paper.defs.appendChild(d),b._blur=d,q(b.node,{filter:"url(#"+d.id+")"})}else b._blur&&(b._blur.parentNode.removeChild(b._blur),delete b._blur,delete b.attrs.blur),b.node.removeAttribute("filter");return b},c._engine.circle=function(a,b,c,d){var e=q("circle");a.canvas&&a.canvas.appendChild(e);var f=new A(e,a);return f.attrs={cx:b,cy:c,r:d,fill:"none",stroke:"#000"},f.type="circle",q(e,f.attrs),f},c._engine.rect=function(a,b,c,d,e,f){var g=q("rect");a.canvas&&a.canvas.appendChild(g);var h=new A(g,a);return h.attrs={x:b,y:c,width:d,height:e,rx:f||0,ry:f||0,fill:"none",stroke:"#000"},h.type="rect",q(g,h.attrs),h},c._engine.ellipse=function(a,b,c,d,e){var f=q("ellipse");a.canvas&&a.canvas.appendChild(f);var g=new A(f,a);return g.attrs={cx:b,cy:c,rx:d,ry:e,fill:"none",stroke:"#000"},g.type="ellipse",q(f,g.attrs),g},c._engine.image=function(a,b,c,d,e,f){var g=q("image");q(g,{x:c,y:d,width:e,height:f,preserveAspectRatio:"none"}),g.setAttributeNS(n,"href",b),a.canvas&&a.canvas.appendChild(g);var h=new A(g,a);return h.attrs={x:c,y:d,width:e,height:f,src:b},h.type="image",h},c._engine.text=function(a,b,d,e){var f=q("text");a.canvas&&a.canvas.appendChild(f);var g=new A(f,a);return g.attrs={x:b,y:d,"text-anchor":"middle",text:e,"font-family":c._availableAttrs["font-family"],"font-size":c._availableAttrs["font-size"],stroke:"none",fill:"#000"},g.type="text",w(g,g.attrs),g},c._engine.setSize=function(a,b){return this.width=a||this.width,this.height=b||this.height,this.canvas.setAttribute("width",this.width),this.canvas.setAttribute("height",this.height),this._viewBox&&this.setViewBox.apply(this,this._viewBox),this},c._engine.create=function(){var a=c._getContainer.apply(0,arguments),b=a&&a.container,d=a.x,e=a.y,f=a.width,g=a.height;if(!b)throw new Error("SVG container not found.");var h,i=q("svg"),j="overflow:hidden;";return d=d||0,e=e||0,f=f||512,g=g||342,q(i,{height:g,version:1.1,width:f,xmlns:"http://www.w3.org/2000/svg","xmlns:xlink":"http://www.w3.org/1999/xlink"}),1==b?(i.style.cssText=j+"position:absolute;left:"+d+"px;top:"+e+"px",c._g.doc.body.appendChild(i),h=1):(i.style.cssText=j+"position:relative",b.firstChild?b.insertBefore(i,b.firstChild):b.appendChild(i)),b=new c._Paper,b.width=f,b.height=g,b.canvas=i,b.clear(),b._left=b._top=0,h&&(b.renderfix=function(){}),b.renderfix(),b},c._engine.setViewBox=function(a,b,c,d,e){k("raphael.setViewBox",this,this._viewBox,[a,b,c,d,e]);var f,h,i=this.getSize(),j=g(c/i.width,d/i.height),l=this.top,n=e?"xMidYMid meet":"xMinYMin";for(null==a?(this._vbSize&&(j=1),delete this._vbSize,f="0 0 "+this.width+m+this.height):(this._vbSize=j,f=a+m+b+m+c+m+d),q(this.canvas,{viewBox:f,preserveAspectRatio:n});j&&l;)h="stroke-width"in l.attrs?l.attrs["stroke-width"]:1,l.attr({"stroke-width":h}),l._.dirty=1,l._.dirtyT=1,l=l.prev;return this._viewBox=[a,b,c,d,!!e],this},c.prototype.renderfix=function(){var a,b=this.canvas,c=b.style;try{a=b.getScreenCTM()||b.createSVGMatrix()}catch(d){a=b.createSVGMatrix()}var e=-a.e%1,f=-a.f%1;(e||f)&&(e&&(this._left=(this._left+e)%1,c.left=this._left+"px"),f&&(this._top=(this._top+f)%1,c.top=this._top+"px"))},c.prototype.clear=function(){c.eve("raphael.clear",this);for(var a=this.canvas;a.firstChild;)a.removeChild(a.firstChild);this.bottom=this.top=null,(this.desc=q("desc")).appendChild(c._g.doc.createTextNode("Created with Raphaël "+c.version)),a.appendChild(this.desc),a.appendChild(this.defs=q("defs"))},c.prototype.remove=function(){k("raphael.remove",this),this.canvas.parentNode&&this.canvas.parentNode.removeChild(this.canvas);for(var a in this)this[a]="function"==typeof this[a]?c._removedFactory(a):null};var C=c.st;for(var D in B)B[a](D)&&!C[a](D)&&(C[D]=function(a){return function(){var b=arguments;return this.forEach(function(c){c[a].apply(c,b)})}}(D))}}(),function(){if(c.vml){var a="hasOwnProperty",b=String,d=parseFloat,e=Math,f=e.round,g=e.max,h=e.min,i=e.abs,j="fill",k=/[, ]+/,l=c.eve,m=" progid:DXImageTransform.Microsoft",n=" ",o="",p={M:"m",L:"l",C:"c",Z:"x",m:"t",l:"r",c:"v",z:"x"},q=/([clmz]),?([^clmz]*)/gi,r=/ progid:\S+Blur\([^\)]+\)/g,s=/-?[^,\s-]+/g,t="position:absolute;left:0;top:0;width:1px;height:1px;behavior:url(#default#VML)",u=21600,v={path:1,rect:1,image:1},w={circle:1,ellipse:1},x=function(a){var d=/[ahqstv]/gi,e=c._pathToAbsolute;if(b(a).match(d)&&(e=c._path2curve),d=/[clmz]/g,e==c._pathToAbsolute&&!b(a).match(d)){var g=b(a).replace(q,function(a,b,c){var d=[],e="m"==b.toLowerCase(),g=p[b];return c.replace(s,function(a){e&&2==d.length&&(g+=d+p["m"==b?"l":"L"],d=[]),d.push(f(a*u))}),g+d});return g}var h,i,j=e(a);g=[];for(var k=0,l=j.length;l>k;k++){h=j[k],i=j[k][0].toLowerCase(),"z"==i&&(i="x");for(var m=1,r=h.length;r>m;m++)i+=f(h[m]*u)+(m!=r-1?",":o);g.push(i)}return g.join(n)},y=function(a,b,d){var e=c.matrix();return e.rotate(-a,.5,.5),{dx:e.x(b,d),dy:e.y(b,d)}},z=function(a,b,c,d,e,f){var g=a._,h=a.matrix,k=g.fillpos,l=a.node,m=l.style,o=1,p="",q=u/b,r=u/c;if(m.visibility="hidden",b&&c){if(l.coordsize=i(q)+n+i(r),m.rotation=f*(0>b*c?-1:1),f){var s=y(f,d,e);d=s.dx,e=s.dy}if(0>b&&(p+="x"),0>c&&(p+=" y")&&(o=-1),m.flip=p,l.coordorigin=d*-q+n+e*-r,k||g.fillsize){var t=l.getElementsByTagName(j);t=t&&t[0],l.removeChild(t),k&&(s=y(f,h.x(k[0],k[1]),h.y(k[0],k[1])),t.position=s.dx*o+n+s.dy*o),g.fillsize&&(t.size=g.fillsize[0]*i(b)+n+g.fillsize[1]*i(c)),l.appendChild(t)}m.visibility="visible"}};c.toString=function(){return"Your browser doesn’t support SVG. Falling down to VML.\nYou are running Raphaël "+this.version};var A=function(a,c,d){for(var e=b(c).toLowerCase().split("-"),f=d?"end":"start",g=e.length,h="classic",i="medium",j="medium";g--;)switch(e[g]){case"block":case"classic":case"oval":case"diamond":case"open":case"none":h=e[g];break;case"wide":case"narrow":j=e[g];break;case"long":case"short":i=e[g]}var k=a.node.getElementsByTagName("stroke")[0];k[f+"arrow"]=h,k[f+"arrowlength"]=i,k[f+"arrowwidth"]=j},B=function(e,i){e.attrs=e.attrs||{};var l=e.node,m=e.attrs,p=l.style,q=v[e.type]&&(i.x!=m.x||i.y!=m.y||i.width!=m.width||i.height!=m.height||i.cx!=m.cx||i.cy!=m.cy||i.rx!=m.rx||i.ry!=m.ry||i.r!=m.r),r=w[e.type]&&(m.cx!=i.cx||m.cy!=i.cy||m.r!=i.r||m.rx!=i.rx||m.ry!=i.ry),s=e;for(var t in i)i[a](t)&&(m[t]=i[t]);if(q&&(m.path=c._getPath[e.type](e),e._.dirty=1),i.href&&(l.href=i.href),i.title&&(l.title=i.title),i.target&&(l.target=i.target),i.cursor&&(p.cursor=i.cursor),"blur"in i&&e.blur(i.blur),(i.path&&"path"==e.type||q)&&(l.path=x(~b(m.path).toLowerCase().indexOf("r")?c._pathToAbsolute(m.path):m.path),e._.dirty=1,"image"==e.type&&(e._.fillpos=[m.x,m.y],e._.fillsize=[m.width,m.height],z(e,1,1,0,0,0))),"transform"in i&&e.transform(i.transform),r){var y=+m.cx,B=+m.cy,D=+m.rx||+m.r||0,E=+m.ry||+m.r||0;l.path=c.format("ar{0},{1},{2},{3},{4},{1},{4},{1}x",f((y-D)*u),f((B-E)*u),f((y+D)*u),f((B+E)*u),f(y*u)),e._.dirty=1}if("clip-rect"in i){var G=b(i["clip-rect"]).split(k);if(4==G.length){G[2]=+G[2]+ +G[0],G[3]=+G[3]+ +G[1];var H=l.clipRect||c._g.doc.createElement("div"),I=H.style;I.clip=c.format("rect({1}px {2}px {3}px {0}px)",G),l.clipRect||(I.position="absolute",I.top=0,I.left=0,I.width=e.paper.width+"px",I.height=e.paper.height+"px",l.parentNode.insertBefore(H,l),H.appendChild(l),l.clipRect=H)}i["clip-rect"]||l.clipRect&&(l.clipRect.style.clip="auto")}if(e.textpath){var J=e.textpath.style;i.font&&(J.font=i.font),i["font-family"]&&(J.fontFamily='"'+i["font-family"].split(",")[0].replace(/^['"]+|['"]+$/g,o)+'"'),i["font-size"]&&(J.fontSize=i["font-size"]),i["font-weight"]&&(J.fontWeight=i["font-weight"]),i["font-style"]&&(J.fontStyle=i["font-style"])}if("arrow-start"in i&&A(s,i["arrow-start"]),"arrow-end"in i&&A(s,i["arrow-end"],1),null!=i.opacity||null!=i["stroke-width"]||null!=i.fill||null!=i.src||null!=i.stroke||null!=i["stroke-width"]||null!=i["stroke-opacity"]||null!=i["fill-opacity"]||null!=i["stroke-dasharray"]||null!=i["stroke-miterlimit"]||null!=i["stroke-linejoin"]||null!=i["stroke-linecap"]){var K=l.getElementsByTagName(j),L=!1;if(K=K&&K[0],!K&&(L=K=F(j)),"image"==e.type&&i.src&&(K.src=i.src),i.fill&&(K.on=!0),(null==K.on||"none"==i.fill||null===i.fill)&&(K.on=!1),K.on&&i.fill){var M=b(i.fill).match(c._ISURL);if(M){K.parentNode==l&&l.removeChild(K),K.rotate=!0,K.src=M[1],K.type="tile";var N=e.getBBox(1);K.position=N.x+n+N.y,e._.fillpos=[N.x,N.y],c._preload(M[1],function(){e._.fillsize=[this.offsetWidth,this.offsetHeight]})}else K.color=c.getRGB(i.fill).hex,K.src=o,K.type="solid",c.getRGB(i.fill).error&&(s.type in{circle:1,ellipse:1}||"r"!=b(i.fill).charAt())&&C(s,i.fill,K)&&(m.fill="none",m.gradient=i.fill,K.rotate=!1)}if("fill-opacity"in i||"opacity"in i){var O=((+m["fill-opacity"]+1||2)-1)*((+m.opacity+1||2)-1)*((+c.getRGB(i.fill).o+1||2)-1);O=h(g(O,0),1),K.opacity=O,K.src&&(K.color="none")}l.appendChild(K);var P=l.getElementsByTagName("stroke")&&l.getElementsByTagName("stroke")[0],Q=!1;!P&&(Q=P=F("stroke")),(i.stroke&&"none"!=i.stroke||i["stroke-width"]||null!=i["stroke-opacity"]||i["stroke-dasharray"]||i["stroke-miterlimit"]||i["stroke-linejoin"]||i["stroke-linecap"])&&(P.on=!0),("none"==i.stroke||null===i.stroke||null==P.on||0==i.stroke||0==i["stroke-width"])&&(P.on=!1);var R=c.getRGB(i.stroke);P.on&&i.stroke&&(P.color=R.hex),O=((+m["stroke-opacity"]+1||2)-1)*((+m.opacity+1||2)-1)*((+R.o+1||2)-1);var S=.75*(d(i["stroke-width"])||1);if(O=h(g(O,0),1),null==i["stroke-width"]&&(S=m["stroke-width"]),i["stroke-width"]&&(P.weight=S),S&&1>S&&(O*=S)&&(P.weight=1),P.opacity=O,i["stroke-linejoin"]&&(P.joinstyle=i["stroke-linejoin"]||"miter"),P.miterlimit=i["stroke-miterlimit"]||8,i["stroke-linecap"]&&(P.endcap="butt"==i["stroke-linecap"]?"flat":"square"==i["stroke-linecap"]?"square":"round"),"stroke-dasharray"in i){var T={"-":"shortdash",".":"shortdot","-.":"shortdashdot","-..":"shortdashdotdot",". ":"dot","- ":"dash","--":"longdash","- .":"dashdot","--.":"longdashdot","--..":"longdashdotdot"};P.dashstyle=T[a](i["stroke-dasharray"])?T[i["stroke-dasharray"]]:o}Q&&l.appendChild(P)}if("text"==s.type){s.paper.canvas.style.display=o;var U=s.paper.span,V=100,W=m.font&&m.font.match(/\d+(?:\.\d*)?(?=px)/);p=U.style,m.font&&(p.font=m.font),m["font-family"]&&(p.fontFamily=m["font-family"]),m["font-weight"]&&(p.fontWeight=m["font-weight"]),m["font-style"]&&(p.fontStyle=m["font-style"]),W=d(m["font-size"]||W&&W[0])||10,p.fontSize=W*V+"px",s.textpath.string&&(U.innerHTML=b(s.textpath.string).replace(/</g,"&#60;").replace(/&/g,"&#38;").replace(/\n/g,"<br>"));var X=U.getBoundingClientRect();s.W=m.w=(X.right-X.left)/V,s.H=m.h=(X.bottom-X.top)/V,s.X=m.x,s.Y=m.y+s.H/2,("x"in i||"y"in i)&&(s.path.v=c.format("m{0},{1}l{2},{1}",f(m.x*u),f(m.y*u),f(m.x*u)+1));for(var Y=["x","y","text","font","font-family","font-weight","font-style","font-size"],Z=0,$=Y.length;$>Z;Z++)if(Y[Z]in i){s._.dirty=1;break}switch(m["text-anchor"]){case"start":s.textpath.style["v-text-align"]="left",s.bbx=s.W/2;break;case"end":s.textpath.style["v-text-align"]="right",s.bbx=-s.W/2;break;default:s.textpath.style["v-text-align"]="center",s.bbx=0}s.textpath.style["v-text-kern"]=!0}},C=function(a,f,g){a.attrs=a.attrs||{};var h=(a.attrs,Math.pow),i="linear",j=".5 .5";if(a.attrs.gradient=f,f=b(f).replace(c._radial_gradient,function(a,b,c){return i="radial",b&&c&&(b=d(b),c=d(c),h(b-.5,2)+h(c-.5,2)>.25&&(c=e.sqrt(.25-h(b-.5,2))*(2*(c>.5)-1)+.5),j=b+n+c),o}),f=f.split(/\s*\-\s*/),"linear"==i){var k=f.shift();if(k=-d(k),isNaN(k))return null}var l=c._parseDots(f);if(!l)return null;if(a=a.shape||a.node,l.length){a.removeChild(g),g.on=!0,g.method="none",g.color=l[0].color,g.color2=l[l.length-1].color;for(var m=[],p=0,q=l.length;q>p;p++)l[p].offset&&m.push(l[p].offset+n+l[p].color);g.colors=m.length?m.join():"0% "+g.color,"radial"==i?(g.type="gradientTitle",g.focus="100%",g.focussize="0 0",g.focusposition=j,g.angle=0):(g.type="gradient",g.angle=(270-k)%360),a.appendChild(g)}return 1},D=function(a,b){this[0]=this.node=a,a.raphael=!0,this.id=c._oid++,a.raphaelid=this.id,this.X=0,this.Y=0,this.attrs={},this.paper=b,this.matrix=c.matrix(),this._={transform:[],sx:1,sy:1,dx:0,dy:0,deg:0,dirty:1,dirtyT:1},!b.bottom&&(b.bottom=this),this.prev=b.top,b.top&&(b.top.next=this),b.top=this,this.next=null},E=c.el;D.prototype=E,E.constructor=D,E.transform=function(a){if(null==a)return this._.transform;var d,e=this.paper._viewBoxShift,f=e?"s"+[e.scale,e.scale]+"-1-1t"+[e.dx,e.dy]:o;e&&(d=a=b(a).replace(/\.{3}|\u2026/g,this._.transform||o)),c._extractTransform(this,f+a);var g,h=this.matrix.clone(),i=this.skew,j=this.node,k=~b(this.attrs.fill).indexOf("-"),l=!b(this.attrs.fill).indexOf("url(");if(h.translate(1,1),l||k||"image"==this.type)if(i.matrix="1 0 0 1",i.offset="0 0",g=h.split(),k&&g.noRotation||!g.isSimple){j.style.filter=h.toFilter();var m=this.getBBox(),p=this.getBBox(1),q=m.x-p.x,r=m.y-p.y;j.coordorigin=q*-u+n+r*-u,z(this,1,1,q,r,0)}else j.style.filter=o,z(this,g.scalex,g.scaley,g.dx,g.dy,g.rotate);else j.style.filter=o,i.matrix=b(h),i.offset=h.offset();return null!==d&&(this._.transform=d,c._extractTransform(this,d)),this},E.rotate=function(a,c,e){if(this.removed)return this;if(null!=a){if(a=b(a).split(k),a.length-1&&(c=d(a[1]),e=d(a[2])),a=d(a[0]),null==e&&(c=e),null==c||null==e){var f=this.getBBox(1);c=f.x+f.width/2,e=f.y+f.height/2}return this._.dirtyT=1,this.transform(this._.transform.concat([["r",a,c,e]])),this}},E.translate=function(a,c){return this.removed?this:(a=b(a).split(k),a.length-1&&(c=d(a[1])),a=d(a[0])||0,c=+c||0,this._.bbox&&(this._.bbox.x+=a,this._.bbox.y+=c),this.transform(this._.transform.concat([["t",a,c]])),this)},E.scale=function(a,c,e,f){if(this.removed)return this;if(a=b(a).split(k),a.length-1&&(c=d(a[1]),e=d(a[2]),f=d(a[3]),isNaN(e)&&(e=null),isNaN(f)&&(f=null)),a=d(a[0]),null==c&&(c=a),null==f&&(e=f),null==e||null==f)var g=this.getBBox(1);return e=null==e?g.x+g.width/2:e,f=null==f?g.y+g.height/2:f,this.transform(this._.transform.concat([["s",a,c,e,f]])),this._.dirtyT=1,this},E.hide=function(){return!this.removed&&(this.node.style.display="none"),this},E.show=function(){return!this.removed&&(this.node.style.display=o),this},E.auxGetBBox=c.el.getBBox,E.getBBox=function(){var a=this.auxGetBBox();if(this.paper&&this.paper._viewBoxShift){var b={},c=1/this.paper._viewBoxShift.scale;return b.x=a.x-this.paper._viewBoxShift.dx,b.x*=c,b.y=a.y-this.paper._viewBoxShift.dy,b.y*=c,b.width=a.width*c,b.height=a.height*c,b.x2=b.x+b.width,b.y2=b.y+b.height,b}return a},E._getBBox=function(){return this.removed?{}:{x:this.X+(this.bbx||0)-this.W/2,y:this.Y-this.H,width:this.W,height:this.H}},E.remove=function(){if(!this.removed&&this.node.parentNode){this.paper.__set__&&this.paper.__set__.exclude(this),c.eve.unbind("raphael.*.*."+this.id),c._tear(this,this.paper),this.node.parentNode.removeChild(this.node),this.shape&&this.shape.parentNode.removeChild(this.shape);for(var a in this)this[a]="function"==typeof this[a]?c._removedFactory(a):null;this.removed=!0}},E.attr=function(b,d){if(this.removed)return this;if(null==b){var e={};for(var f in this.attrs)this.attrs[a](f)&&(e[f]=this.attrs[f]);return e.gradient&&"none"==e.fill&&(e.fill=e.gradient)&&delete e.gradient,e.transform=this._.transform,e}if(null==d&&c.is(b,"string")){if(b==j&&"none"==this.attrs.fill&&this.attrs.gradient)return this.attrs.gradient;for(var g=b.split(k),h={},i=0,m=g.length;m>i;i++)b=g[i],h[b]=b in this.attrs?this.attrs[b]:c.is(this.paper.customAttributes[b],"function")?this.paper.customAttributes[b].def:c._availableAttrs[b];return m-1?h:h[g[0]]}if(this.attrs&&null==d&&c.is(b,"array")){for(h={},i=0,m=b.length;m>i;i++)h[b[i]]=this.attr(b[i]);return h}var n;null!=d&&(n={},n[b]=d),null==d&&c.is(b,"object")&&(n=b);for(var o in n)l("raphael.attr."+o+"."+this.id,this,n[o]);if(n){for(o in this.paper.customAttributes)if(this.paper.customAttributes[a](o)&&n[a](o)&&c.is(this.paper.customAttributes[o],"function")){var p=this.paper.customAttributes[o].apply(this,[].concat(n[o]));this.attrs[o]=n[o];for(var q in p)p[a](q)&&(n[q]=p[q])}n.text&&"text"==this.type&&(this.textpath.string=n.text),B(this,n)}return this},E.toFront=function(){return!this.removed&&this.node.parentNode.appendChild(this.node),this.paper&&this.paper.top!=this&&c._tofront(this,this.paper),this},E.toBack=function(){return this.removed?this:(this.node.parentNode.firstChild!=this.node&&(this.node.parentNode.insertBefore(this.node,this.node.parentNode.firstChild),c._toback(this,this.paper)),this)},E.insertAfter=function(a){return this.removed?this:(a.constructor==c.st.constructor&&(a=a[a.length-1]),a.node.nextSibling?a.node.parentNode.insertBefore(this.node,a.node.nextSibling):a.node.parentNode.appendChild(this.node),c._insertafter(this,a,this.paper),this)},E.insertBefore=function(a){return this.removed?this:(a.constructor==c.st.constructor&&(a=a[0]),a.node.parentNode.insertBefore(this.node,a.node),c._insertbefore(this,a,this.paper),this)},E.blur=function(a){var b=this.node.runtimeStyle,d=b.filter;return d=d.replace(r,o),0!==+a?(this.attrs.blur=a,b.filter=d+n+m+".Blur(pixelradius="+(+a||1.5)+")",b.margin=c.format("-{0}px 0 0 -{0}px",f(+a||1.5))):(b.filter=d,b.margin=0,delete this.attrs.blur),this},c._engine.path=function(a,b){var c=F("shape");c.style.cssText=t,c.coordsize=u+n+u,c.coordorigin=b.coordorigin;var d=new D(c,b),e={fill:"none",stroke:"#000"};a&&(e.path=a),d.type="path",d.path=[],d.Path=o,B(d,e),b.canvas.appendChild(c);var f=F("skew");return f.on=!0,c.appendChild(f),d.skew=f,d.transform(o),d},c._engine.rect=function(a,b,d,e,f,g){var h=c._rectPath(b,d,e,f,g),i=a.path(h),j=i.attrs;return i.X=j.x=b,i.Y=j.y=d,i.W=j.width=e,i.H=j.height=f,j.r=g,j.path=h,i.type="rect",i},c._engine.ellipse=function(a,b,c,d,e){{var f=a.path();f.attrs}return f.X=b-d,f.Y=c-e,f.W=2*d,f.H=2*e,f.type="ellipse",B(f,{cx:b,cy:c,rx:d,ry:e}),f},c._engine.circle=function(a,b,c,d){{var e=a.path();e.attrs}return e.X=b-d,e.Y=c-d,e.W=e.H=2*d,e.type="circle",B(e,{cx:b,cy:c,r:d}),e},c._engine.image=function(a,b,d,e,f,g){var h=c._rectPath(d,e,f,g),i=a.path(h).attr({stroke:"none"}),k=i.attrs,l=i.node,m=l.getElementsByTagName(j)[0];return k.src=b,i.X=k.x=d,i.Y=k.y=e,i.W=k.width=f,i.H=k.height=g,k.path=h,i.type="image",m.parentNode==l&&l.removeChild(m),m.rotate=!0,m.src=b,m.type="tile",i._.fillpos=[d,e],i._.fillsize=[f,g],l.appendChild(m),z(i,1,1,0,0,0),i},c._engine.text=function(a,d,e,g){var h=F("shape"),i=F("path"),j=F("textpath");d=d||0,e=e||0,g=g||"",i.v=c.format("m{0},{1}l{2},{1}",f(d*u),f(e*u),f(d*u)+1),i.textpathok=!0,j.string=b(g),j.on=!0,h.style.cssText=t,h.coordsize=u+n+u,h.coordorigin="0 0";var k=new D(h,a),l={fill:"#000",stroke:"none",font:c._availableAttrs.font,text:g};k.shape=h,k.path=i,k.textpath=j,k.type="text",k.attrs.text=b(g),k.attrs.x=d,k.attrs.y=e,k.attrs.w=1,k.attrs.h=1,B(k,l),h.appendChild(j),h.appendChild(i),a.canvas.appendChild(h);var m=F("skew");return m.on=!0,h.appendChild(m),k.skew=m,k.transform(o),k},c._engine.setSize=function(a,b){var d=this.canvas.style;return this.width=a,this.height=b,a==+a&&(a+="px"),b==+b&&(b+="px"),d.width=a,d.height=b,d.clip="rect(0 "+a+" "+b+" 0)",this._viewBox&&c._engine.setViewBox.apply(this,this._viewBox),this},c._engine.setViewBox=function(a,b,d,e,f){c.eve("raphael.setViewBox",this,this._viewBox,[a,b,d,e,f]);var g,h,i=this.getSize(),j=i.width,k=i.height;return f&&(g=k/e,h=j/d,j>d*g&&(a-=(j-d*g)/2/g),k>e*h&&(b-=(k-e*h)/2/h)),this._viewBox=[a,b,d,e,!!f],this._viewBoxShift={dx:-a,dy:-b,scale:i},this.forEach(function(a){a.transform("...")}),this};var F;c._engine.initWin=function(a){var b=a.document;b.styleSheets.length<31?b.createStyleSheet().addRule(".rvml","behavior:url(#default#VML)"):b.styleSheets[0].addRule(".rvml","behavior:url(#default#VML)");try{!b.namespaces.rvml&&b.namespaces.add("rvml","urn:schemas-microsoft-com:vml"),F=function(a){return b.createElement("<rvml:"+a+' class="rvml">')}}catch(c){F=function(a){return b.createElement("<"+a+' xmlns="urn:schemas-microsoft.com:vml" class="rvml">')}}},c._engine.initWin(c._g.win),c._engine.create=function(){var a=c._getContainer.apply(0,arguments),b=a.container,d=a.height,e=a.width,f=a.x,g=a.y;if(!b)throw new Error("VML container not found.");var h=new c._Paper,i=h.canvas=c._g.doc.createElement("div"),j=i.style;return f=f||0,g=g||0,e=e||512,d=d||342,h.width=e,h.height=d,e==+e&&(e+="px"),d==+d&&(d+="px"),h.coordsize=1e3*u+n+1e3*u,h.coordorigin="0 0",h.span=c._g.doc.createElement("span"),h.span.style.cssText="position:absolute;left:-9999em;top:-9999em;padding:0;margin:0;line-height:1;",i.appendChild(h.span),j.cssText=c.format("top:0;left:0;width:{0};height:{1};display:inline-block;position:relative;clip:rect(0 {0} {1} 0);overflow:hidden",e,d),1==b?(c._g.doc.body.appendChild(i),j.left=f+"px",j.top=g+"px",j.position="absolute"):b.firstChild?b.insertBefore(i,b.firstChild):b.appendChild(i),h.renderfix=function(){},h},c.prototype.clear=function(){c.eve("raphael.clear",this),this.canvas.innerHTML=o,this.span=c._g.doc.createElement("span"),this.span.style.cssText="position:absolute;left:-9999em;top:-9999em;padding:0;margin:0;line-height:1;display:inline;",this.canvas.appendChild(this.span),this.bottom=this.top=null},c.prototype.remove=function(){c.eve("raphael.remove",this),this.canvas.parentNode.removeChild(this.canvas);for(var a in this)this[a]="function"==typeof this[a]?c._removedFactory(a):null;return!0};var G=c.st;for(var H in E)E[a](H)&&!G[a](H)&&(G[H]=function(a){return function(){var b=arguments;return this.forEach(function(c){c[a].apply(c,b)})}}(H))}}(),B.was?A.win.Raphael=c:Raphael=c,"object"==typeof exports&&(module.exports=c),c});
/**
 * @fileoverview Small utility JavaScript for setting up the scenario explorer frame for testing and
 *     development.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */
 
/* $(document).ready(function()
{
    var scenario_names = ["Djatoka Default", "Fedora Default", "10+ Crops (1)", "10+ Crops (2)", 
                          "Multiple Crops &amp; Rotations (1)",  
                          "Multiple Crops &amp; Rotations (2)", 
                          "Multiple Crops &amp; Rotations (3)", "Polygons (1)", "Polygons (2)", 
                          "Polygons (3)", "Saved Crop (1)", "Saved Crop (2)", "Saved Crop (3)", 
                          "Change Crop ID", "Delete Crop"];
    var scenario_pages = ["djtoka", "fedora-default", "ten-plus", "ten-plus-2", "multi-1", 
                          "multi-2", "multi-3","polygon-1", "polygon-2", "polygon-3", "saved-1", 
                          "saved-2", "saved-3","change-id", "delete"];

    var html = "";
    
    for (var i = 0; i < scenario_names.length && i < scenario_pages.length; i++)
    {
        html += "<option value=\"" + scenario_pages[i] + "\">" + scenario_names[i] + "</option>";
    }
    
    $("select#user-scenarios").html(html);

    $("select#user-scenarios").change(function()
    {
        parent.tool.document.location =  $(this).val() + ".html";
    });
    
    // parent.tool.document.location =  scenario_pages[0] + ".html";
}); */

;
/**
 * Site-specific URLs for fetching Crop Tool content.
 */

 
var Site = {};

/**
 * Creates a URL that creates the crop specified by the given dimensions.
 */
 
Site.createCropUrl = function(x, y, width, height, image)
{
	return "/multiresimages/create_crop.xml?pid=" + image + "&x=" + x + "&y=" + y + "&width=" + width + "&height=" + height;
};

/**
 * Creates a URL for fetching a single crop by PID.
 */

Site.fetchCropUrl = function(pid)
{
	return "/multiresimages/svg/" + pid ;
};

Site.fetchRawImageUrl = function(pid)
{
	return "/multiresimages/svg/" + pid ;
};

Site.putCropUrl = function(pid)
{
	return "/multiresimages/updatecrop/" + pid;
};

Site.thumbnailImageUrl = function(pid, img_width, img_height, req_width, req_height)
{
	return "http://cecil.library.northwestern.edu:8983/fedora/get/" + pid + "/inu:sdef-image/getCropWithSize?" + "destheight=" + img_height + 
		   "&destwidth=" + img_width + "&x=0&y=0&height=" + Math.floor(req_height) + "&width=" + Math.floor(req_width);
};

Site.tileUrl = function(img_path, level, x, y)
{
	return "/multiresimages/aware_tile?file_path=" + img_path + "&level=" + level + "&x=" + x + "&y=" + y;
};

Site.fetchImageUrl = function(pid)
{
	return Site.fetchCropUrl(pid);
};

Site.iconPath = function()
{
	return "/assets/croptool/";
};

Site.catalogPathForPid = function(pid)
{
	return "/catalog/" + pid;
};

Site.multiresimagePathForPid = function(pid)
{
	return pid;
};
/*global alert */


var PersistenceManager = {};

PersistenceManager.initialize = function(image)
{
	this.image = image;
	CropManager.crops = PersistenceManager.fetchCrops();
};

PersistenceManager.requestNewCrop = function()
{
	var vp = CoordinateManager.currentActualViewport();

	if (vp.x < 0)
	{
		vp.width = vp.width + vp.x;
		vp.x = 0;
	}

	if (vp.y < 0)
	{
		vp.height = vp.height + vp.y;
		vp.y = 0;
	}

	if ((vp.x + vp.width) > 	ImageServer.details.width)
		vp.width = ImageServer.details.width - vp.x;
		
	if ((vp.height + vp.y) > ImageServer.details.height)
		vp.height = ImageServer.details.height - vp.y;
	
	var fetch_url = Site.createCropUrl(vp.x, vp.y, vp.width, vp.height, ImageServer.image);
     
    //show the loading gif 
    
    $('.modal-collection').show();
	$.get(fetch_url, function(data) 
	{
		// TODO: Check for <error /> return
		var pid = $(data).find("success").attr("pid");
        
        //redirect to crop's show view
		window.location = Site.multiresimagePathForPid(pid);
	});
};

PersistenceManager.loadCrop = function(pid)
{
	if (pid === undefined)
	{
		alert("Undefined PID. Check your URLs.");
		
		return;
	}

	var url = Site.fetchCropUrl(pid);

	$.ajax({ url: url, async:false, success: function(data) 
	{
		if (data.length === 0)
		{
			alert("PersistenceManager.loadCrop: Unable to fetch " + url + ". Check that everything is served from the same host.");
			return;
		}

		// Assumes 256x256 size for all tiles...
		
		var img_width = Math.ceil(ImageServer.details.width / ImageServer.tile_size) * ImageServer.tile_size;
		var img_height = Math.ceil(ImageServer.details.height / ImageServer.tile_size) * ImageServer.tile_size;

		var rects = $(data).find("rect");

		if (rects.length == 0)
			rects = $(data).find("svg\\:rect");
		
		rects.each(function()
		{
			var crop = CropManager.createNewCrop();
			crop.pid = pid;
			
			var x = parseInt($(this).attr("x"), 10);
			var y = parseInt($(this).attr("y"), 10);
			var width = parseInt($(this).attr("width"), 10);
			var height = parseInt($(this).attr("height"), 10);

			var cx = x + (width / 2);
			var cy = y + (height / 2);
			
			crop.cx = cx / img_width;
			crop.width = width / img_width;
			crop.cy = cy / img_height;
			crop.height = height / img_height;

			// TODO: More in line with SVG spec...

			// rotate(45 7891 4736.5)

			if ($(this).attr("transform"))
			{
				var transformString = $(this).attr("transform");

				var index = transformString.search("rotate");

				if (index != -1)
				{
					transformString = transformString.substring(index);
	
					var start = 6; // Had trouble doing .search("(")...
					var end = transformString.search(" ");

					if (end != -1)
					{
						var rotate = transformString.substring(start + 1, end);
			
						crop.rotation = parseInt(rotate, 10);
					}
				} 
			}

			if (crop.rotation === undefined)
				crop.rotation = 0;
			
			if ($(this).attr("style"))
			{
				var styleString = $(this).attr("style");
				
				var index = styleString.search("#");

				if (index != -1)
					crop.color = styleString.substring(index, index + 7);
			}
					
			if (crop.color === undefined)
				crop.color = "#888888";

			CropManager.crops.push(crop); // TODO: Add crop method on CropManager...

			MetadataManager.refresh();
			CropManager.updatePosition();				

			ControlManager.toFront();
		});
		
		if (CropManager.crops.length > 0)
		{
			setTimeout(function()
			{
				CropManager.crops[0].setViewPort();
				
				CropManager.setEditable(false);
				
				ControlManager.toFront();
				
			}, 100);
		}
	}, error: function(jqXHR, textStatus, errorThrown)
	{
		alert("PersistenceManager.fetchCrops: Unable to fetch " + url + ". Check that everything is served from the same host.");
	}});
};

PersistenceManager.saveCrop = function(crop)
{
	var prefix = '<?xml version="1.0"?>';
	prefix += '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ct="http://library.northwestern.edu/crop-tool" ';

	prefix += 'height="' + ImageServer.details.o_height + '" width="' + ImageServer.details.o_width + '">';
	
	// TODO: Site URL for xlink:href element...

	prefix += '<image style="overflow: auto" height="' + ImageServer.details.o_height + '" width="'
				 + ImageServer.details.o_width + '" xlink:href="' + gon.url + Math.floor(ImageServer.details.o_width / 10) + "&amp;viewheight=" 
				 + Math.floor(ImageServer.details.o_height / 10) +"&amp;filename=" + ImageServer.imagePath + '" />';

	var suffix = '</svg>';

	var crop_width = Math.floor(ImageServer.details.width * crop.width);
	var crop_height = Math.floor(ImageServer.details.height * crop.height);
	var crop_x = Math.floor(ImageServer.details.width * (crop.cx - (crop.width / 2)));
	var crop_y = Math.floor(ImageServer.details.height * (crop.cy - (crop.height / 2)));

	var mid_x = crop_x + (crop_width / 2);
	var mid_y = crop_y + (crop_height / 2);

	var rectString = '<rect height="' + crop_height + '" width="' + crop_width + '" x="' + crop_x + '" y="' + crop_y + '" '
					+ 'style="fill:' + crop.color + ';stroke:' + crop.color + ';opacity:0.5;" '
					+ 'transform="rotate(' + crop.rotation + ' ' + mid_x + ' ' + mid_y + ')">';
//						+ 'ct:rotation="' + crop.rotation + '" ct:color="' + crop.color + '">';

	rectString += "</rect>";
		
	var xmlString = prefix + rectString + suffix;

	alert("posting " + xmlString);
		
	var post_url = Site.putCropUrl(crop.pid);
		
	alert("saving to " + post_url);
		
	$.ajax({
		url: post_url,
		contentType: "text/xml",
		data: xmlString,
		type: "POST",
		success:  function(data)
		{
			alert("Crop data saved (" + crop.pid + ").");
		}
	});
};

PersistenceManager.saveCrops = function(crops)
{
	alert("PersistenceManager.saveCrops deprecated. Please check your sources.");
};

PersistenceManager.fetchCrops = function()
{
	PersistenceManager.loadCrop(PersistenceManager.image);

	return CropManager.crops;
};
/*global $, CoordinateManager, ImageServer, CropTool, CropManager, ControlManager, setTimeout */

/**
 * @fileoverview This file contains the code that manages the display of the tiled images in the 
 *     main view. Works with the image server to obtain tiles.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */


var TileManager = {};

TileManager.cacheImages = [];

TileManager.tiles = [];
TileManager.remaining = 0;

/**
 * Refreshes the position of the individual tiles.
 */
 
TileManager.updatePosition = function()
{
    for (var i = 0; i < TileManager.tiles.length; i++)
    {
        TileManager.tiles[i].updatePosition();
    }
    
    ControlManager.toFront();
};

/**
 * Removes the tiles and resets the display.
 */
 
TileManager.reset = function()
{
    while (TileManager.tiles.length > 0)
    {
        TileManager.tiles.shift().remove();
    }
};

/**
 * Loads a tile for a given position in the grid.
 */
 
TileManager.loadTile = function(i, j, level)
{
    if (i < 0 || j < 0)
        return;
        
    var glass = CoordinateManager.glass;

    var tile_url = ImageServer.tileAt(i, j, level, ImageServer.tile_size);
    
    if (tile_url !== null && glass.loadedTiles[i + "." + j] === undefined)
    {
        glass.loadedTiles[i + "." + j] = true;

        TileManager.remaining += 1;
        
        // After the tile image is fetched, position the tile approriately...

        var callback = function(img_element, context)
        {
            TileManager.remaining -= 1;
    
            if (img_element === null)
            {

            }
            else if (context.level !== CoordinateManager.current_level)
            {

            }
            else
            {
                var cx = context.glass.attr("x") + (context.glass.o_width / 2);
                var cy = context.glass.attr("y") + (context.glass.o_height / 2);
                
                var glass_origin_x = cx - (context.glass.o_width / 2);
                var glass_origin_y = cy - (context.glass.o_height / 2);
                
                var img_width = $(img_element).width(); // .attr("width");
                var img_height = $(img_element).height(); // .attr("height");

                var x = glass_origin_x + (context.i * ImageServer.tile_size);
                var y = glass_origin_y + (context.j * ImageServer.tile_size);
                
                var image = CropTool.paper.image($(img_element).attr("src"), x, y, img_width, 
                								 img_height);
                TileManager.tiles.push(image);

                image.glass = context.glass;
                image.i = context.i;
                image.j = context.j;

                image.updatePosition = function ()
                {
                    var cx = this.glass.attr("x") + (context.glass.o_width / 2);
                    var cy = this.glass.attr("y") + (context.glass.o_height / 2);
                
                    var glass_origin_x = cx - (this.glass.o_width / 2);
                    var glass_origin_y = cy - (this.glass.o_height / 2);

                    var x = glass_origin_x + (this.i * ImageServer.tile_size);
                    var y = glass_origin_y + (this.j * ImageServer.tile_size);
                    
                    this.attr("x", x);
                    this.attr("y", y);

                    this.rotate(this.glass.rotation, cx, cy);

                    image.toFront();
                    context.glass.toFront();
                };

                image.toFront();

                context.glass.toFront();

                CropManager.toFront();
                ControlManager.toFront();
                
                image.rotate(context.glass.rotation, cx, cy);

                $(img_element).remove();
            }   

			// After all tiles are loaded, revert to "move" mode...
			
            if (TileManager.remaining === 0)
            {
                $("body").css("cursor", "move");

/*                if (TileManager.cacheImages.length > 0)
                {
                    while (TileManager.cacheImages.length > 128)
                    {
                        TileManager.cacheImages.shift();
                    }

                    var f = function ()
                    {
                        if (TileManager.cacheImages.length > 0)
                        {
                            var subtile_url = TileManager.cacheImages.pop(); // .shift();
    
                            var cache_callback = function(img_element, context)
                            {
                                $(img_element).remove();

                                setTimeout(f, 100);
                            };
                        
                            ImageServer.queueImage(subtile_url, cache_callback, null);
                        }
                    };

                    setTimeout(f, 100);
                } */
                TileManager.updatePosition();
            }
            
            // Prefetch the four tiles underneath this one for performance reasons...
        
/*            for (var i_offset = 0; i_offset < 2; i_offset++)
            {
                for (var j_offset = 0; j_offset < 2; j_offset++)
                {
                    var subtile_url = ImageServer.tileAt((context.i * 2) + i_offset, (context.j * 2)
                    								     + j_offset, context.level + 1, 
                    								     ImageServer.tile_size);
                
                    if (subtile_url !== null)
                    {
                        TileManager.cacheImages.push(subtile_url);
                    }
                }
            }
  */      };

        var context = {};
        context.i = i; 
        context.j = j;
        context.level = level;
        context.glass = glass;

        ImageServer.queueImage(tile_url, callback, context);
    }
};
/**
 *
 * Utilities
 * Author: Stefan Petre www.eyecon.ro
 * 
 */

(function($) {
EYE.extend({
	getPosition : function(e, forceIt)
	{
		var x = 0;
		var y = 0;
		var es = e.style;
		var restoreStyles = false;
		if (forceIt && jQuery.curCSS(e,'display') == 'none') {
			var oldVisibility = es.visibility;
			var oldPosition = es.position;
			restoreStyles = true;
			es.visibility = 'hidden';
			es.display = 'block';
			es.position = 'absolute';
		}
		var el = e;
		if (el.getBoundingClientRect) { // IE
			var box = el.getBoundingClientRect();
			x = box.left + Math.max(document.documentElement.scrollLeft, document.body.scrollLeft) - 2;
			y = box.top + Math.max(document.documentElement.scrollTop, document.body.scrollTop) - 2;
		} else {
			x = el.offsetLeft;
			y = el.offsetTop;
			el = el.offsetParent;
			if (e != el) {
				while (el) {
					x += el.offsetLeft;
					y += el.offsetTop;
					el = el.offsetParent;
				}
			}
			if (jQuery.browser.safari && jQuery.curCSS(e, 'position') == 'absolute' ) {
				x -= document.body.offsetLeft;
				y -= document.body.offsetTop;
			}
			el = e.parentNode;
			while (el && el.tagName.toUpperCase() != 'BODY' && el.tagName.toUpperCase() != 'HTML') 
			{
				if (jQuery.curCSS(el, 'display') != 'inline') {
					x -= el.scrollLeft;
					y -= el.scrollTop;
				}
				el = el.parentNode;
			}
		}
		if (restoreStyles == true) {
			es.display = 'none';
			es.position = oldPosition;
			es.visibility = oldVisibility;
		}
		return {x:x, y:y};
	},
	getSize : function(e)
	{
		var w = parseInt(jQuery.curCSS(e,'width'), 10);
		var h = parseInt(jQuery.curCSS(e,'height'), 10);
		var wb = 0;
		var hb = 0;
		if (jQuery.curCSS(e, 'display') != 'none') {
			wb = e.offsetWidth;
			hb = e.offsetHeight;
		} else {
			var es = e.style;
			var oldVisibility = es.visibility;
			var oldPosition = es.position;
			es.visibility = 'hidden';
			es.display = 'block';
			es.position = 'absolute';
			wb = e.offsetWidth;
			hb = e.offsetHeight;
			es.display = 'none';
			es.position = oldPosition;
			es.visibility = oldVisibility;
		}
		return {w:w, h:h, wb:wb, hb:hb};
	},
	getClient : function(e)
	{
		var h, w;
		if (e) {
			w = e.clientWidth;
			h = e.clientHeight;
		} else {
			var de = document.documentElement;
			w = window.innerWidth || self.innerWidth || (de&&de.clientWidth) || document.body.clientWidth;
			h = window.innerHeight || self.innerHeight || (de&&de.clientHeight) || document.body.clientHeight;
		}
		return {w:w,h:h};
	},
	getScroll : function (e)
	{
		var t=0, l=0, w=0, h=0, iw=0, ih=0;
		if (e && e.nodeName.toLowerCase() != 'body') {
			t = e.scrollTop;
			l = e.scrollLeft;
			w = e.scrollWidth;
			h = e.scrollHeight;
		} else  {
			if (document.documentElement) {
				t = document.documentElement.scrollTop;
				l = document.documentElement.scrollLeft;
				w = document.documentElement.scrollWidth;
				h = document.documentElement.scrollHeight;
			} else if (document.body) {
				t = document.body.scrollTop;
				l = document.body.scrollLeft;
				w = document.body.scrollWidth;
				h = document.body.scrollHeight;
			}
			if (typeof pageYOffset != 'undefined') {
				t = pageYOffset;
				l = pageXOffset;
			}
			iw = self.innerWidth||document.documentElement.clientWidth||document.body.clientWidth||0;
			ih = self.innerHeight||document.documentElement.clientHeight||document.body.clientHeight||0;
		}
		return { t: t, l: l, w: w, h: h, iw: iw, ih: ih };
	},
	getMargins : function(e, toInteger)
	{
		var t = jQuery.curCSS(e,'marginTop') || '';
		var r = jQuery.curCSS(e,'marginRight') || '';
		var b = jQuery.curCSS(e,'marginBottom') || '';
		var l = jQuery.curCSS(e,'marginLeft') || '';
		if (toInteger)
			return {
				t: parseInt(t, 10)||0,
				r: parseInt(r, 10)||0,
				b: parseInt(b, 10)||0,
				l: parseInt(l, 10)
			};
		else
			return {t: t, r: r,	b: b, l: l};
	},
	getPadding : function(e, toInteger)
	{
		var t = jQuery.curCSS(e,'paddingTop') || '';
		var r = jQuery.curCSS(e,'paddingRight') || '';
		var b = jQuery.curCSS(e,'paddingBottom') || '';
		var l = jQuery.curCSS(e,'paddingLeft') || '';
		if (toInteger)
			return {
				t: parseInt(t, 10)||0,
				r: parseInt(r, 10)||0,
				b: parseInt(b, 10)||0,
				l: parseInt(l, 10)
			};
		else
			return {t: t, r: r,	b: b, l: l};
	},
	getBorder : function(e, toInteger)
	{
		var t = jQuery.curCSS(e,'borderTopWidth') || '';
		var r = jQuery.curCSS(e,'borderRightWidth') || '';
		var b = jQuery.curCSS(e,'borderBottomWidth') || '';
		var l = jQuery.curCSS(e,'borderLeftWidth') || '';
		if (toInteger)
			return {
				t: parseInt(t, 10)||0,
				r: parseInt(r, 10)||0,
				b: parseInt(b, 10)||0,
				l: parseInt(l, 10)||0
			};
		else
			return {t: t, r: r,	b: b, l: l};
	},
	traverseDOM : function(nodeEl, func)
	{
		func(nodeEl);
		nodeEl = nodeEl.firstChild;
		while(nodeEl){
			EYE.traverseDOM(nodeEl, func);
			nodeEl = nodeEl.nextSibling;
		}
	},
	getInnerWidth :  function(el, scroll) {
		var offsetW = el.offsetWidth;
		return scroll ? Math.max(el.scrollWidth,offsetW) - offsetW + el.clientWidth:el.clientWidth;
	},
	getInnerHeight : function(el, scroll) {
		var offsetH = el.offsetHeight;
		return scroll ? Math.max(el.scrollHeight,offsetH) - offsetH + el.clientHeight:el.clientHeight;
	},
	getExtraWidth : function(el) {
		if($.boxModel)
			return (parseInt($.curCSS(el, 'paddingLeft'))||0)
				+ (parseInt($.curCSS(el, 'paddingRight'))||0)
				+ (parseInt($.curCSS(el, 'borderLeftWidth'))||0)
				+ (parseInt($.curCSS(el, 'borderRightWidth'))||0);
		return 0;
	},
	getExtraHeight : function(el) {
		if($.boxModel)
			return (parseInt($.curCSS(el, 'paddingTop'))||0)
				+ (parseInt($.curCSS(el, 'paddingBottom'))||0)
				+ (parseInt($.curCSS(el, 'borderTopWidth'))||0)
				+ (parseInt($.curCSS(el, 'borderBottomWidth'))||0);
		return 0;
	},
	isChildOf: function(parentEl, el, container) {
		if (parentEl == el) {
			return true;
		}
		if (!el || !el.nodeType || el.nodeType != 1) {
			return false;
		}
		if (parentEl.contains && !$.browser.safari) {
			return parentEl.contains(el);
		}
		if ( parentEl.compareDocumentPosition ) {
			return !!(parentEl.compareDocumentPosition(el) & 16);
		}
		var prEl = el.parentNode;
		while(prEl && prEl != container) {
			if (prEl == parentEl)
				return true;
			prEl = prEl.parentNode;
		}
		return false;
	},
	centerEl : function(el, axis)
	{
		var clientScroll = EYE.getScroll();
		var size = EYE.getSize(el);
		if (!axis || axis == 'vertically')
			$(el).css(
				{
					top: clientScroll.t + ((Math.min(clientScroll.h,clientScroll.ih) - size.hb)/2) + 'px'
				}
			);
		if (!axis || axis == 'horizontally')
			$(el).css(
				{
					left: clientScroll.l + ((Math.min(clientScroll.w,clientScroll.iw) - size.wb)/2) + 'px'
				}
			);
	}
});
if (!$.easing.easeout) {
	$.easing.easeout = function(p, n, firstNum, delta, duration) {
		return -delta * ((n=n/duration-1)*n*n*n - 1) + firstNum;
	};
}
	
})(jQuery);
