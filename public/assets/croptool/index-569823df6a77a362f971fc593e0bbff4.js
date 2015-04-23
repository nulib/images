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
(function($){$.jQTouch=function(_2){$.support.WebKitCSSMatrix=(typeof WebKitCSSMatrix=="object");$.support.touch=(typeof Touch=="object");$.support.WebKitAnimationEvent=(typeof WebKitTransitionEvent=="object");var _3,$head=$("head"),hist=[],newPageCount=0,jQTSettings={},hashCheck,currentPage,orientation,isMobileWebKit=RegExp(" Mobile/").test(navigator.userAgent),tapReady=true,lastAnimationTime=0,touchSelectors=[],publicObj={},extensions=$.jQTouch.prototype.extensions,defaultAnimations=["slide","flip","slideup","swap","cube","pop","dissolve","fade","back"],animations=[],hairextensions="";init(_2);function init(_4){var _5={addGlossToIcon:true,backSelector:".back, .cancel, .goback",cacheGetRequests:true,cubeSelector:".cube",dissolveSelector:".dissolve",fadeSelector:".fade",fixedViewport:true,flipSelector:".flip",formSelector:"form",fullScreen:true,fullScreenClass:"fullscreen",icon:null,touchSelector:"a, .touch",popSelector:".pop",preloadImages:false,slideSelector:"body > * > ul li a",slideupSelector:".slideup",startupScreen:null,statusBar:"default",submitSelector:".submit",swapSelector:".swap",useAnimations:true,useFastTouch:true};jQTSettings=$.extend({},_5,_4);if(jQTSettings.preloadImages){for(var i=jQTSettings.preloadImages.length-1;i>=0;i--){(new Image()).src=jQTSettings.preloadImages[i];}}if(jQTSettings.icon){var _7=(jQTSettings.addGlossToIcon)?"":"-precomposed";hairextensions+="<link rel=\"apple-touch-icon"+_7+"\" href=\""+jQTSettings.icon+"\" />";}if(jQTSettings.startupScreen){hairextensions+="<link rel=\"apple-touch-startup-image\" href=\""+jQTSettings.startupScreen+"\" />";}if(jQTSettings.fixedViewport){hairextensions+="<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0;\"/>";}if(jQTSettings.fullScreen){hairextensions+="<meta name=\"apple-mobile-web-app-capable\" content=\"yes\" />";if(jQTSettings.statusBar){hairextensions+="<meta name=\"apple-mobile-web-app-status-bar-style\" content=\""+jQTSettings.statusBar+"\" />";}}if(hairextensions){$head.append(hairextensions);}$(document).ready(function(){for(var i in extensions){var fn=extensions[i];if($.isFunction(fn)){$.extend(publicObj,fn(publicObj));}}for(var i in defaultAnimations){var _a=defaultAnimations[i];var _b=jQTSettings[_a+"Selector"];if(typeof (_b)=="string"){addAnimation({name:_a,selector:_b});}}touchSelectors.push("input");touchSelectors.push(jQTSettings.touchSelector);touchSelectors.push(jQTSettings.backSelector);touchSelectors.push(jQTSettings.submitSelector);$(touchSelectors.join(", ")).css("-webkit-touch-callout","none");$(jQTSettings.backSelector).tap(liveTap);$(jQTSettings.submitSelector).tap(submitParentForm);_3=$("body");if(jQTSettings.fullScreenClass&&window.navigator.standalone==true){_3.addClass(jQTSettings.fullScreenClass+" "+jQTSettings.statusBar);}_3.bind("touchstart",handleTouch).bind("orientationchange",updateOrientation).trigger("orientationchange").submit(submitForm);if(jQTSettings.useFastTouch&&$.support.touch){_3.click(function(e){var _d=$(e.target);if(_d.attr("target")=="_blank"||_d.attr("rel")=="external"||_d.is("input[type=\"checkbox\"]")){return true;}else{return false;}});_3.mousedown(function(e){var _f=(new Date()).getTime()-lastAnimationTime;if(_f<200){return false;}});}if($("body > .current").length==0){currentPage=$("body > *:first");}else{currentPage=$("body > .current:first");$("body > .current").removeClass("current");}$(currentPage).addClass("current");location.hash=$(currentPage).attr("id");addPageToHistory(currentPage);scrollTo(0,0);dumbLoopStart();});}function goBack(to){if(hist.length>1){var _11=Math.min(parseInt(to||1,10),hist.length-1);if(isNaN(_11)&&typeof (to)==="string"&&to!="#"){for(var i=1,length=hist.length;i<length;i++){if("#"+hist[i].id===to){_11=i;break;}}}if(isNaN(_11)||_11<1){_11=1;}var _13=hist[0].animation;var _14=hist[0].page;hist.splice(0,_11);var _15=hist[0].page;animatePages(_14,_15,_13,true);return publicObj;}else{console.error("No pages in history.");return false;}}function goTo(_16,_17){var _18=hist[0].page;if(typeof (_16)==="string"){_16=$(_16);}if(typeof (_17)==="string"){for(var i=animations.length-1;i>=0;i--){if(animations[i].name===_17){_17=animations[i];break;}}}if(animatePages(_18,_16,_17)){addPageToHistory(_16,_17);return publicObj;}else{console.error("Could not animate pages.");return false;}}function getOrientation(){return orientation;}function liveTap(e){var $el=$(e.target);if($el.attr("nodeName")!=="A"){$el=$el.parent("a");}var _1c=$el.attr("target"),hash=$el.attr("hash"),animation=null;if(tapReady==false||!$el.length){console.warn("Not able to tap element.");return false;}if($el.attr("target")=="_blank"||$el.attr("rel")=="external"){return true;}for(var i=animations.length-1;i>=0;i--){if($el.is(animations[i].selector)){animation=animations[i];break;}}if(_1c=="_webapp"){window.location=$el.attr("href");}else{if($el.is(jQTSettings.backSelector)){goBack(hash);}else{if(hash&&hash!="#"){$el.addClass("active");goTo($(hash).data("referrer",$el),animation);}else{$el.addClass("loading active");showPageByHref($el.attr("href"),{animation:animation,callback:function(){$el.removeClass("loading");setTimeout($.fn.unselect,250,$el);},$referrer:$el});}}}return false;}function addPageToHistory(_1e,_1f){var _20=_1e.attr("id");hist.unshift({page:_1e,animation:_1f,id:_20});}function animatePages(_21,_22,_23,_24){if(_22.length===0){$.fn.unselect();console.error("Target element is missing.");return false;}$(":focus").blur();scrollTo(0,0);var _25=function(_26){if(_23){_22.removeClass("in reverse "+_23.name);_21.removeClass("current out reverse "+_23.name);}else{_21.removeClass("current");}_22.trigger("pageAnimationEnd",{direction:"in"});_21.trigger("pageAnimationEnd",{direction:"out"});clearInterval(dumbLoop);currentPage=_22;location.hash=currentPage.attr("id");dumbLoopStart();var _27=_22.data("referrer");if(_27){_27.unselect();}lastAnimationTime=(new Date()).getTime();tapReady=true;};_21.trigger("pageAnimationStart",{direction:"out"});_22.trigger("pageAnimationStart",{direction:"in"});if($.support.WebKitAnimationEvent&&_23&&jQTSettings.useAnimations){_22.one("webkitAnimationEnd",_25);tapReady=false;_22.addClass(_23.name+" in current "+(_24?" reverse":""));_21.addClass(_23.name+" out"+(_24?" reverse":""));}else{_22.addClass("current");_25();}return true;}function dumbLoopStart(){dumbLoop=setInterval(function(){var _28=currentPage.attr("id");if(location.hash==""){location.hash="#"+_28;}else{if(location.hash!="#"+_28){try{goBack(location.hash);}catch(e){console.error("Unknown hash change.");}}}},100);}function insertPages(_29,_2a){var _2b=null;$(_29).each(function(_2c,_2d){var _2e=$(this);if(!_2e.attr("id")){_2e.attr("id","page-"+(++newPageCount));}_2e.appendTo(_3);if(_2e.hasClass("current")||!_2b){_2b=_2e;}});if(_2b!==null){goTo(_2b,_2a);return _2b;}else{return false;}}function showPageByHref(_2f,_30){var _31={data:null,method:"GET",animation:null,callback:null,$referrer:null};var _32=$.extend({},_31,_30);if(_2f!="#"){$.ajax({url:_2f,data:_32.data,type:_32.method,success:function(_33,_34){var _35=insertPages(_33,_32.animation);if(_35){if(_32.method=="GET"&&jQTSettings.cacheGetRequests&&_32.$referrer){_32.$referrer.attr("href","#"+_35.attr("id"));}if(_32.callback){_32.callback(true);}}},error:function(_36){if(_32.$referrer){_32.$referrer.unselect();}if(_32.callback){_32.callback(false);}}});}else{if($referrer){$referrer.unselect();}}}function submitForm(e,_38){var _39=(typeof (e)==="string")?$(e):$(e.target);if(_39.length&&_39.is(jQTSettings.formSelector)&&_39.attr("action")){showPageByHref(_39.attr("action"),{data:_39.serialize(),method:_39.attr("method")||"POST",animation:animations[0]||null,callback:_38});return false;}return true;}function submitParentForm(e){var _3b=$(this).closest("form");if(_3b.length){evt=jQuery.Event("submit");evt.preventDefault();_3b.trigger(evt);return false;}return true;}function addAnimation(_3c){if(typeof (_3c.selector)=="string"&&typeof (_3c.name)=="string"){animations.push(_3c);$(_3c.selector).tap(liveTap);touchSelectors.push(_3c.selector);}}function updateOrientation(){orientation=window.innerWidth<window.innerHeight?"profile":"landscape";_3.removeClass("profile landscape").addClass(orientation).trigger("turn",{orientation:orientation});}function handleTouch(e){var $el=$(e.target);if(!$(e.target).is(touchSelectors.join(", "))){var _3f=$(e.target).closest("a");if(_3f.length){$el=_3f;}else{return;}}if(event){var _40=null,startX=event.changedTouches[0].clientX,startY=event.changedTouches[0].clientY,startTime=(new Date).getTime(),deltaX=0,deltaY=0,deltaT=0;$el.bind("touchmove",touchmove).bind("touchend",touchend);_40=setTimeout(function(){$el.makeActive();},100);}function touchmove(e){updateChanges();var _42=Math.abs(deltaX);var _43=Math.abs(deltaY);if(_42>_43&&(_42>35)&&deltaT<1000){$el.trigger("swipe",{direction:(deltaX<0)?"left":"right"}).unbind("touchmove touchend");}else{if(_43>1){$el.removeClass("active");}}clearTimeout(_40);}function touchend(){updateChanges();if(deltaY===0&&deltaX===0){$el.makeActive();$el.trigger("tap");}else{$el.removeClass("active");}$el.unbind("touchmove touchend");clearTimeout(_40);}function updateChanges(){var _44=event.changedTouches[0]||null;deltaX=_44.pageX-startX;deltaY=_44.pageY-startY;deltaT=(new Date).getTime()-startTime;}}$.fn.unselect=function(obj){if(obj){obj.removeClass("active");}else{$(".active").removeClass("active");}};$.fn.makeActive=function(){return $(this).addClass("active");};$.fn.swipe=function(fn){if($.isFunction(fn)){return this.each(function(i,el){$(el).bind("swipe",fn);});}};$.fn.tap=function(fn){if($.isFunction(fn)){var _4a=(jQTSettings.useFastTouch&&$.support.touch)?"tap":"click";return $(this).live(_4a,fn);}else{$(this).trigger("tap");}};publicObj={getOrientation:getOrientation,goBack:goBack,goTo:goTo,addAnimation:addAnimation,submitForm:submitForm};return publicObj;};$.jQTouch.prototype.extensions=[];$.jQTouch.addExtension=function(_4b){$.jQTouch.prototype.extensions.push(_4b);};})(jQuery);
/*

            _/    _/_/    _/_/_/_/_/                              _/       
               _/    _/      _/      _/_/    _/    _/    _/_/_/  _/_/_/    
          _/  _/  _/_/      _/    _/    _/  _/    _/  _/        _/    _/   
         _/  _/    _/      _/    _/    _/  _/    _/  _/        _/    _/    
        _/    _/_/  _/    _/      _/_/      _/_/_/    _/_/_/  _/    _/     
       _/                                                                  
    _/

    Created by David Kaneda <http://www.davidkaneda.com>
    Documentation and issue tracking on Google Code <http://code.google.com/p/jqtouch/>
    
    Special thanks to Jonathan Stark <http://jonathanstark.com/>
    and pinch/zoom <http://www.pinchzoom.com/>
    
    (c) 2009 by jQTouch project members.
    See LICENSE.txt for license.

*/


(function($) {
    
    $.fn.transition = function(css, options) {
        return this.each(function(){
            var $el = $(this);
            var defaults = {
                speed : '300ms',
                callback: null,
                ease: 'ease-in-out'
            };
            var settings = $.extend({}, defaults, options);
            if(settings.speed === 0) {
                $el.css(css);
                window.setTimeout(settings.callback, 0);
            } else {
                if ($.browser.safari)
                {
                    var s = [];
                    for(var i in css) {
                        s.push(i);
                    }
                    $el.css({
                        webkitTransitionProperty: s.join(", "), 
                        webkitTransitionDuration: settings.speed, 
                        webkitTransitionTimingFunction: settings.ease
                    });
                    if (settings.callback) {
                        $el.one('webkitTransitionEnd', settings.callback);
                    }
                    setTimeout(function(el){ el.css(css) }, 0, $el);
                }
                else
                {
                    $el.animate(css, settings.speed, settings.callback);
                }
            }
        });
    }
})(jQuery);
/*!
 * jQuery corner plugin: simple corner rounding
 * Examples and documentation at: http://jquery.malsup.com/corner/
 * version 2.11 (15-JUN-2010)
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

var style = document.createElement('div').style,
    moz = style['MozBorderRadius'] !== undefined,
    webkit = style['WebkitBorderRadius'] !== undefined,
    radius = style['borderRadius'] !== undefined || style['BorderRadius'] !== undefined,
    mode = document.documentMode || 0,
    noBottomFold = $.browser.msie && (($.browser.version < 8 && !mode) || mode < 8),

    expr = $.browser.msie && (function() {
        var div = document.createElement('div');
        try { div.style.setExpression('width','0+0'); div.style.removeExpression('width'); }
        catch(e) { return false; }
        return true;
    })();

$.support = $.support || {};
$.support.borderRadius = moz || webkit || radius; // so you can do:  if (!$.support.borderRadius) $('#myDiv').corner();

function sz(el, p) { 
    return parseInt($.css(el,p))||0; 
};
function hex2(s) {
    var s = parseInt(s).toString(16);
    return ( s.length < 2 ) ? '0'+s : s;
};
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
};

function getWidth(fx, i, width) {
    switch(fx) {
    case 'round':  return Math.round(width*(1-Math.cos(Math.asin(i/width))));
    case 'cool':   return Math.round(width*(1+Math.cos(Math.asin(i/width))));
    case 'sharp':  return Math.round(width*(1-Math.cos(Math.acos(i/width))));
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
    }
};

$.fn.corner = function(options) {
    // in 1.3+ we can fix mistakes with the ready state
    if (this.length == 0) {
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
            width = parseInt((o.match(/(\d+)px/)||[])[1]) || 10, // corner width
            re = /round|bevelfold|bevel|notch|bite|cool|sharp|slide|jut|curl|tear|fray|wicked|sculpt|long|dog3|dog2|dogfold|dog/,
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
            T: parseInt($.css(this,'paddingTop'))||0,     R: parseInt($.css(this,'paddingRight'))||0,
            B: parseInt($.css(this,'paddingBottom'))||0,  L: parseInt($.css(this,'paddingLeft'))||0
        };

        if (typeof this.style.zoom != undefined) this.style.zoom = 1; // force 'hasLayout' in IE
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
                else if (!bot && $.browser.msie) {
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
/*! Copyright (c) 2010 Brandon Aaron (http://brandonaaron.net)
 * Licensed under the MIT License (LICENSE.txt).
 *
 * Thanks to: http://adomas.org/javascript-mouse-wheel/ for some pointers.
 * Thanks to: Mathias Bank(http://www.mathias-bank.de) for a scope bug fix.
 * Thanks to: Seamus Leahy for adding deltaX and deltaY
 *
 * Version: 3.0.4
 * 
 * Requires: 1.2.2+
 */


(function($) {

var types = ['DOMMouseScroll', 'mousewheel'];

$.event.special.mousewheel = {
    setup: function() {
        if ( this.addEventListener ) {
            for ( var i=types.length; i; ) {
                this.addEventListener( types[--i], handler, false );
            }
        } else {
            this.onmousewheel = handler;
        }
    },
    
    teardown: function() {
        if ( this.removeEventListener ) {
            for ( var i=types.length; i; ) {
                this.removeEventListener( types[--i], handler, false );
            }
        } else {
            this.onmousewheel = null;
        }
    }
};

$.fn.extend({
    mousewheel: function(fn) {
        return fn ? this.bind("mousewheel", fn) : this.trigger("mousewheel");
    },
    
    unmousewheel: function(fn) {
        return this.unbind("mousewheel", fn);
    }
});


function handler(event) {
    var orgEvent = event || window.event, args = [].slice.call( arguments, 1 ), delta = 0, returnValue = true, deltaX = 0, deltaY = 0;
    event = $.event.fix(orgEvent);
    event.type = "mousewheel";
    
    // Old school scrollwheel delta
    if ( event.wheelDelta ) { delta = event.wheelDelta/120; }
    if ( event.detail     ) { delta = -event.detail/3; }
    
    // New school multidimensional scroll (touchpads) deltas
    deltaY = delta;
    
    // Gecko
    if ( orgEvent.axis !== undefined && orgEvent.axis === orgEvent.HORIZONTAL_AXIS ) {
        deltaY = 0;
        deltaX = -1*delta;
    }
    
    // Webkit
    if ( orgEvent.wheelDeltaY !== undefined ) { deltaY = orgEvent.wheelDeltaY/120; }
    if ( orgEvent.wheelDeltaX !== undefined ) { deltaX = -1*orgEvent.wheelDeltaX/120; }
    
    // Add event and delta to the front of the arguments
    args.unshift(event, delta, deltaX, deltaY);
    
    return $.event.handle.apply(this, args);
}

})(jQuery);
(function($){
	var initLayout = function() {
		var hash = window.location.hash.replace('#', '');
		var currentTab = $('ul.navigationTabs a')
							.bind('click', showTab)
							.filter('a[rel=' + hash + ']');
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


/*
 * Raphael 1.4.3 - JavaScript Vector Library
 *
 * Copyright (c) 2010 Dmitry Baranovskiy (http://raphaeljs.com)
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
 */

Raphael=function(){function m(){if(m.is(arguments[0],U)){for(var a=arguments[0],b=Aa[K](m,a.splice(0,3+m.is(a[0],O))),c=b.set(),d=0,f=a[o];d<f;d++){var e=a[d]||{};nb.test(e.type)&&c[E](b[e.type]().attr(e))}return c}return Aa[K](m,arguments)}m.version="1.4.3";var V=/[, ]+/,nb=/^(circle|rect|path|ellipse|text|image)$/,p="prototype",z="hasOwnProperty",C=document,X=window,La={was:Object[p][z].call(X,"Raphael"),is:X.Raphael};function G(){}var y="appendChild",K="apply",M="concat",Ba="createTouch"in C,s=
"",P=" ",H="split",Ma="click dblclick mousedown mousemove mouseout mouseover mouseup touchstart touchmove touchend orientationchange touchcancel gesturestart gesturechange gestureend"[H](P),Ca={mousedown:"touchstart",mousemove:"touchmove",mouseup:"touchend"},Q="join",o="length",ca=String[p].toLowerCase,w=Math,Y=w.max,$=w.min,O="number",ea="string",U="array",N="toString",aa="fill",ob=Object[p][N],D=w.pow,E="push",ga=/^(?=[\da-f]$)/,Na=/^url\(['"]?([^\)]+?)['"]?\)$/i,pb=/^\s*((#[a-f\d]{6})|(#[a-f\d]{3})|rgba?\(\s*([\d\.]+\s*,\s*[\d\.]+\s*,\s*[\d\.]+(?:\s*,\s*[\d\.]+)?)\s*\)|rgba?\(\s*([\d\.]+%\s*,\s*[\d\.]+%\s*,\s*[\d\.]+%(?:\s*,\s*[\d\.]+%))\s*\)|hs[bl]\(\s*([\d\.]+\s*,\s*[\d\.]+\s*,\s*[\d\.]+)\s*\)|hs[bl]\(\s*([\d\.]+%\s*,\s*[\d\.]+%\s*,\s*[\d\.]+%)\s*\))\s*$/i,
F=w.round,W="setAttribute",A=parseFloat,da=parseInt,Da=" progid:DXImageTransform.Microsoft",pa=String[p].toUpperCase,qa={blur:0,"clip-rect":"0 0 1e9 1e9",cursor:"default",cx:0,cy:0,fill:"#fff","fill-opacity":1,font:'10px "Arial"',"font-family":'"Arial"',"font-size":"10","font-style":"normal","font-weight":400,gradient:0,height:0,href:"http://raphaeljs.com/",opacity:1,path:"M0,0",r:0,rotation:0,rx:0,ry:0,scale:"1 1",src:"",stroke:"#000","stroke-dasharray":"","stroke-linecap":"butt","stroke-linejoin":"butt",
"stroke-miterlimit":0,"stroke-opacity":1,"stroke-width":1,target:"_blank","text-anchor":"middle",title:"Raphael",translation:"0 0",width:0,x:0,y:0},Ea={along:"along",blur:O,"clip-rect":"csv",cx:O,cy:O,fill:"colour","fill-opacity":O,"font-size":O,height:O,opacity:O,path:"path",r:O,rotation:"csv",rx:O,ry:O,scale:"csv",stroke:"colour","stroke-opacity":O,"stroke-width":O,translation:"csv",width:O,x:O,y:O},I="replace";m.type=X.SVGAngle||C.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure",
"1.1")?"SVG":"VML";if(m.type=="VML"){var ha=C.createElement("div");ha.innerHTML="<!--[if vml]><br><br><![endif]--\>";if(ha.childNodes[o]!=2)return m.type=null;ha=null}m.svg=!(m.vml=m.type=="VML");G[p]=m[p];m._id=0;m._oid=0;m.fn={};m.is=function(a,b){b=ca.call(b);return b=="object"&&a===Object(a)||b=="undefined"&&typeof a==b||b=="null"&&a==null||ca.call(ob.call(a).slice(8,-1))==b};m.setWindow=function(a){X=a;C=X.document};function ra(a){if(m.vml){var b=/^\s+|\s+$/g;ra=T(function(d){var f;d=(d+s)[I](b,
s);try{var e=new X.ActiveXObject("htmlfile");e.write("<body>");e.close();f=e.body}catch(g){f=X.createPopup().document.body}e=f.createTextRange();try{f.style.color=d;var h=e.queryCommandValue("ForeColor");h=(h&255)<<16|h&65280|(h&16711680)>>>16;return"#"+("000000"+h[N](16)).slice(-6)}catch(i){return"none"}})}else{var c=C.createElement("i");c.title="Rapha\u00ebl Colour Picker";c.style.display="none";C.body[y](c);ra=T(function(d){c.style.color=d;return C.defaultView.getComputedStyle(c,s).getPropertyValue("color")})}return ra(a)}
function qb(){return"hsb("+[this.h,this.s,this.b]+")"}function rb(){return this.hex}m.hsb2rgb=T(function(a,b,c){if(m.is(a,"object")&&"h"in a&&"s"in a&&"b"in a){c=a.b;b=a.s;a=a.h}var d;if(c==0)return{r:0,g:0,b:0,hex:"#000"};if(a>1||b>1||c>1){a/=255;b/=255;c/=255}d=~~(a*6);a=a*6-d;var f=c*(1-b),e=c*(1-b*a),g=c*(1-b*(1-a));a=[c,e,f,f,g,c,c][d];b=[g,c,c,e,f,f,g][d];d=[f,f,g,c,c,e,f][d];a*=255;b*=255;d*=255;c={r:a,g:b,b:d,toString:rb};a=(~~a)[N](16);b=(~~b)[N](16);d=(~~d)[N](16);a=a[I](ga,"0");b=b[I](ga,
"0");d=d[I](ga,"0");c.hex="#"+a+b+d;return c},m);m.rgb2hsb=T(function(a,b,c){if(m.is(a,"object")&&"r"in a&&"g"in a&&"b"in a){c=a.b;b=a.g;a=a.r}if(m.is(a,ea)){var d=m.getRGB(a);a=d.r;b=d.g;c=d.b}if(a>1||b>1||c>1){a/=255;b/=255;c/=255}var f=Y(a,b,c),e=$(a,b,c);d=f;if(e==f)return{h:0,s:0,b:f};else{var g=f-e;e=g/f;a=a==f?(b-c)/g:b==f?2+(c-a)/g:4+(a-b)/g;a/=6;a<0&&a++;a>1&&a--}return{h:a,s:e,b:d,toString:qb}},m);var sb=/,?([achlmqrstvxz]),?/gi,sa=/\s*,\s*/,tb={hs:1,rg:1};m._path2string=function(){return this.join(",")[I](sb,
"$1")};function T(a,b,c){function d(){var f=Array[p].slice.call(arguments,0),e=f[Q]("\u25ba"),g=d.cache=d.cache||{},h=d.count=d.count||[];if(g[z](e))return c?c(g[e]):g[e];h[o]>=1000&&delete g[h.shift()];h[E](e);g[e]=a[K](b,f);return c?c(g[e]):g[e]}return d}m.getRGB=T(function(a){if(!a||(a+=s).indexOf("-")+1)return{r:-1,g:-1,b:-1,hex:"none",error:1};if(a=="none")return{r:-1,g:-1,b:-1,hex:"none"};!(tb[z](a.substring(0,2))||a.charAt()=="#")&&(a=ra(a));var b,c,d,f,e;if(a=a.match(pb)){if(a[2]){d=da(a[2].substring(5),
16);c=da(a[2].substring(3,5),16);b=da(a[2].substring(1,3),16)}if(a[3]){d=da((e=a[3].charAt(3))+e,16);c=da((e=a[3].charAt(2))+e,16);b=da((e=a[3].charAt(1))+e,16)}if(a[4]){a=a[4][H](sa);b=A(a[0]);c=A(a[1]);d=A(a[2]);f=A(a[3])}if(a[5]){a=a[5][H](sa);b=A(a[0])*2.55;c=A(a[1])*2.55;d=A(a[2])*2.55;f=A(a[3])}if(a[6]){a=a[6][H](sa);b=A(a[0]);c=A(a[1]);d=A(a[2]);return m.hsb2rgb(b,c,d)}if(a[7]){a=a[7][H](sa);b=A(a[0])*2.55;c=A(a[1])*2.55;d=A(a[2])*2.55;return m.hsb2rgb(b,c,d)}a={r:b,g:c,b:d};b=(~~b)[N](16);
c=(~~c)[N](16);d=(~~d)[N](16);b=b[I](ga,"0");c=c[I](ga,"0");d=d[I](ga,"0");a.hex="#"+b+c+d;isFinite(A(f))&&(a.o=f);return a}return{r:-1,g:-1,b:-1,hex:"none",error:1}},m);m.getColor=function(a){a=this.getColor.start=this.getColor.start||{h:0,s:1,b:a||0.75};var b=this.hsb2rgb(a.h,a.s,a.b);a.h+=0.075;if(a.h>1){a.h=0;a.s-=0.2;a.s<=0&&(this.getColor.start={h:0,s:1,b:a.b})}return b.hex};m.getColor.reset=function(){delete this.start};var ub=/([achlmqstvz])[\s,]*((-?\d*\.?\d*(?:e[-+]?\d+)?\s*,?\s*)+)/ig,
vb=/(-?\d*\.?\d*(?:e[-+]?\d+)?)\s*,?\s*/ig;m.parsePathString=T(function(a){if(!a)return null;var b={a:7,c:6,h:1,l:2,m:2,q:4,s:4,t:2,v:1,z:0},c=[];if(m.is(a,U)&&m.is(a[0],U))c=ta(a);c[o]||(a+s)[I](ub,function(d,f,e){var g=[];d=ca.call(f);e[I](vb,function(h,i){i&&g[E](+i)});if(d=="m"&&g[o]>2){c[E]([f][M](g.splice(0,2)));d="l";f=f=="m"?"l":"L"}for(;g[o]>=b[d];){c[E]([f][M](g.splice(0,b[d])));if(!b[d])break}});c[N]=m._path2string;return c});m.findDotsAtSegment=function(a,b,c,d,f,e,g,h,i){var j=1-i,l=
D(j,3)*a+D(j,2)*3*i*c+j*3*i*i*f+D(i,3)*g;j=D(j,3)*b+D(j,2)*3*i*d+j*3*i*i*e+D(i,3)*h;var n=a+2*i*(c-a)+i*i*(f-2*c+a),r=b+2*i*(d-b)+i*i*(e-2*d+b),q=c+2*i*(f-c)+i*i*(g-2*f+c),k=d+2*i*(e-d)+i*i*(h-2*e+d);a=(1-i)*a+i*c;b=(1-i)*b+i*d;f=(1-i)*f+i*g;e=(1-i)*e+i*h;h=90-w.atan((n-q)/(r-k))*180/w.PI;(n>q||r<k)&&(h+=180);return{x:l,y:j,m:{x:n,y:r},n:{x:q,y:k},start:{x:a,y:b},end:{x:f,y:e},alpha:h}};var va=T(function(a){if(!a)return{x:0,y:0,width:0,height:0};a=ua(a);for(var b=0,c=0,d=[],f=[],e,g=0,h=a[o];g<h;g++){e=
a[g];if(e[0]=="M"){b=e[1];c=e[2];d[E](b);f[E](c)}else{b=wb(b,c,e[1],e[2],e[3],e[4],e[5],e[6]);d=d[M](b.min.x,b.max.x);f=f[M](b.min.y,b.max.y);b=e[5];c=e[6]}}a=$[K](0,d);e=$[K](0,f);return{x:a,y:e,width:Y[K](0,d)-a,height:Y[K](0,f)-e}});function ta(a){var b=[];if(!m.is(a,U)||!m.is(a&&a[0],U))a=m.parsePathString(a);for(var c=0,d=a[o];c<d;c++){b[c]=[];for(var f=0,e=a[c][o];f<e;f++)b[c][f]=a[c][f]}b[N]=m._path2string;return b}var Oa=T(function(a){if(!m.is(a,U)||!m.is(a&&a[0],U))a=m.parsePathString(a);
var b=[],c=0,d=0,f=0,e=0,g=0;if(a[0][0]=="M"){c=a[0][1];d=a[0][2];f=c;e=d;g++;b[E](["M",c,d])}g=g;for(var h=a[o];g<h;g++){var i=b[g]=[],j=a[g];if(j[0]!=ca.call(j[0])){i[0]=ca.call(j[0]);switch(i[0]){case "a":i[1]=j[1];i[2]=j[2];i[3]=j[3];i[4]=j[4];i[5]=j[5];i[6]=+(j[6]-c).toFixed(3);i[7]=+(j[7]-d).toFixed(3);break;case "v":i[1]=+(j[1]-d).toFixed(3);break;case "m":f=j[1];e=j[2];default:for(var l=1,n=j[o];l<n;l++)i[l]=+(j[l]-(l%2?c:d)).toFixed(3)}}else{b[g]=[];if(j[0]=="m"){f=j[1]+c;e=j[2]+d}i=0;for(l=
j[o];i<l;i++)b[g][i]=j[i]}j=b[g][o];switch(b[g][0]){case "z":c=f;d=e;break;case "h":c+=+b[g][j-1];break;case "v":d+=+b[g][j-1];break;default:c+=+b[g][j-2];d+=+b[g][j-1]}}b[N]=m._path2string;return b},0,ta),ka=T(function(a){if(!m.is(a,U)||!m.is(a&&a[0],U))a=m.parsePathString(a);var b=[],c=0,d=0,f=0,e=0,g=0;if(a[0][0]=="M"){c=+a[0][1];d=+a[0][2];f=c;e=d;g++;b[0]=["M",c,d]}g=g;for(var h=a[o];g<h;g++){var i=b[g]=[],j=a[g];if(j[0]!=pa.call(j[0])){i[0]=pa.call(j[0]);switch(i[0]){case "A":i[1]=j[1];i[2]=
j[2];i[3]=j[3];i[4]=j[4];i[5]=j[5];i[6]=+(j[6]+c);i[7]=+(j[7]+d);break;case "V":i[1]=+j[1]+d;break;case "H":i[1]=+j[1]+c;break;case "M":f=+j[1]+c;e=+j[2]+d;default:for(var l=1,n=j[o];l<n;l++)i[l]=+j[l]+(l%2?c:d)}}else{l=0;for(n=j[o];l<n;l++)b[g][l]=j[l]}switch(i[0]){case "Z":c=f;d=e;break;case "H":c=i[1];break;case "V":d=i[1];break;default:c=b[g][b[g][o]-2];d=b[g][b[g][o]-1]}}b[N]=m._path2string;return b},null,ta);function wa(a,b,c,d){return[a,b,c,d,c,d]}function Pa(a,b,c,d,f,e){var g=1/3,h=2/3;return[g*
a+h*c,g*b+h*d,g*f+h*c,g*e+h*d,f,e]}function Qa(a,b,c,d,f,e,g,h,i,j){var l=w.PI,n=l*120/180,r=l/180*(+f||0),q=[],k,t=T(function(J,fa,xa){var xb=J*w.cos(xa)-fa*w.sin(xa);J=J*w.sin(xa)+fa*w.cos(xa);return{x:xb,y:J}});if(j){x=j[0];k=j[1];e=j[2];B=j[3]}else{k=t(a,b,-r);a=k.x;b=k.y;k=t(h,i,-r);h=k.x;i=k.y;w.cos(l/180*f);w.sin(l/180*f);k=(a-h)/2;x=(b-i)/2;B=k*k/(c*c)+x*x/(d*d);if(B>1){B=w.sqrt(B);c=B*c;d=B*d}B=c*c;var L=d*d;B=(e==g?-1:1)*w.sqrt(w.abs((B*L-B*x*x-L*k*k)/(B*x*x+L*k*k)));e=B*c*x/d+(a+h)/2;var B=
B*-d*k/c+(b+i)/2,x=w.asin(((b-B)/d).toFixed(7));k=w.asin(((i-B)/d).toFixed(7));x=a<e?l-x:x;k=h<e?l-k:k;x<0&&(x=l*2+x);k<0&&(k=l*2+k);if(g&&x>k)x-=l*2;if(!g&&k>x)k-=l*2}l=k-x;if(w.abs(l)>n){q=k;l=h;L=i;k=x+n*(g&&k>x?1:-1);h=e+c*w.cos(k);i=B+d*w.sin(k);q=Qa(h,i,c,d,f,0,g,l,L,[k,q,e,B])}l=k-x;f=w.cos(x);e=w.sin(x);g=w.cos(k);k=w.sin(k);l=w.tan(l/4);c=4/3*c*l;l=4/3*d*l;d=[a,b];a=[a+c*e,b-l*f];b=[h+c*k,i-l*g];h=[h,i];a[0]=2*d[0]-a[0];a[1]=2*d[1]-a[1];if(j)return[a,b,h][M](q);else{q=[a,b,h][M](q)[Q]()[H](",");
j=[];h=0;for(i=q[o];h<i;h++)j[h]=h%2?t(q[h-1],q[h],r).y:t(q[h],q[h+1],r).x;return j}}function la(a,b,c,d,f,e,g,h,i){var j=1-i;return{x:D(j,3)*a+D(j,2)*3*i*c+j*3*i*i*f+D(i,3)*g,y:D(j,3)*b+D(j,2)*3*i*d+j*3*i*i*e+D(i,3)*h}}var wb=T(function(a,b,c,d,f,e,g,h){var i=f-2*c+a-(g-2*f+c),j=2*(c-a)-2*(f-c),l=a-c,n=(-j+w.sqrt(j*j-4*i*l))/2/i;i=(-j-w.sqrt(j*j-4*i*l))/2/i;var r=[b,h],q=[a,g];w.abs(n)>1000000000000&&(n=0.5);w.abs(i)>1000000000000&&(i=0.5);if(n>0&&n<1){n=la(a,b,c,d,f,e,g,h,n);q[E](n.x);r[E](n.y)}if(i>
0&&i<1){n=la(a,b,c,d,f,e,g,h,i);q[E](n.x);r[E](n.y)}i=e-2*d+b-(h-2*e+d);j=2*(d-b)-2*(e-d);l=b-d;n=(-j+w.sqrt(j*j-4*i*l))/2/i;i=(-j-w.sqrt(j*j-4*i*l))/2/i;w.abs(n)>1000000000000&&(n=0.5);w.abs(i)>1000000000000&&(i=0.5);if(n>0&&n<1){n=la(a,b,c,d,f,e,g,h,n);q[E](n.x);r[E](n.y)}if(i>0&&i<1){n=la(a,b,c,d,f,e,g,h,i);q[E](n.x);r[E](n.y)}return{min:{x:$[K](0,q),y:$[K](0,r)},max:{x:Y[K](0,q),y:Y[K](0,r)}}}),ua=T(function(a,b){var c=ka(a),d=b&&ka(b);a={x:0,y:0,bx:0,by:0,X:0,Y:0,qx:null,qy:null};b={x:0,y:0,
bx:0,by:0,X:0,Y:0,qx:null,qy:null};function f(q,k){var t;if(!q)return["C",k.x,k.y,k.x,k.y,k.x,k.y];!(q[0]in{T:1,Q:1})&&(k.qx=k.qy=null);switch(q[0]){case "M":k.X=q[1];k.Y=q[2];break;case "A":q=["C"][M](Qa[K](0,[k.x,k.y][M](q.slice(1))));break;case "S":t=k.x+(k.x-(k.bx||k.x));k=k.y+(k.y-(k.by||k.y));q=["C",t,k][M](q.slice(1));break;case "T":k.qx=k.x+(k.x-(k.qx||k.x));k.qy=k.y+(k.y-(k.qy||k.y));q=["C"][M](Pa(k.x,k.y,k.qx,k.qy,q[1],q[2]));break;case "Q":k.qx=q[1];k.qy=q[2];q=["C"][M](Pa(k.x,k.y,q[1],
q[2],q[3],q[4]));break;case "L":q=["C"][M](wa(k.x,k.y,q[1],q[2]));break;case "H":q=["C"][M](wa(k.x,k.y,q[1],k.y));break;case "V":q=["C"][M](wa(k.x,k.y,k.x,q[1]));break;case "Z":q=["C"][M](wa(k.x,k.y,k.X,k.Y));break}return q}function e(q,k){if(q[k][o]>7){q[k].shift();for(var t=q[k];t[o];)q.splice(k++,0,["C"][M](t.splice(0,6)));q.splice(k,1);i=Y(c[o],d&&d[o]||0)}}function g(q,k,t,L,B){if(q&&k&&q[B][0]=="M"&&k[B][0]!="M"){k.splice(B,0,["M",L.x,L.y]);t.bx=0;t.by=0;t.x=q[B][1];t.y=q[B][2];i=Y(c[o],d&&
d[o]||0)}}for(var h=0,i=Y(c[o],d&&d[o]||0);h<i;h++){c[h]=f(c[h],a);e(c,h);d&&(d[h]=f(d[h],b));d&&e(d,h);g(c,d,a,b,h);g(d,c,b,a,h);var j=c[h],l=d&&d[h],n=j[o],r=d&&l[o];a.x=j[n-2];a.y=j[n-1];a.bx=A(j[n-4])||a.x;a.by=A(j[n-3])||a.y;b.bx=d&&(A(l[r-4])||b.x);b.by=d&&(A(l[r-3])||b.y);b.x=d&&l[r-2];b.y=d&&l[r-1]}return d?[c,d]:c},null,ta),Ra=T(function(a){for(var b=[],c=0,d=a[o];c<d;c++){var f={},e=a[c].match(/^([^:]*):?([\d\.]*)/);f.color=m.getRGB(e[1]);if(f.color.error)return null;f.color=f.color.hex;
e[2]&&(f.offset=e[2]+"%");b[E](f)}c=1;for(d=b[o]-1;c<d;c++)if(!b[c].offset){a=A(b[c-1].offset||0);e=0;for(f=c+1;f<d;f++)if(b[f].offset){e=b[f].offset;break}if(!e){e=100;f=d}e=A(e);for(e=(e-a)/(f-c+1);c<f;c++){a+=e;b[c].offset=a+"%"}}return b});function Sa(a,b,c,d){if(m.is(a,ea)||m.is(a,"object")){a=m.is(a,ea)?C.getElementById(a):a;if(a.tagName)return b==null?{container:a,width:a.style.pixelWidth||a.offsetWidth,height:a.style.pixelHeight||a.offsetHeight}:{container:a,width:b,height:c}}else return{container:1,
x:a,y:b,width:c,height:d}}function Fa(a,b){var c=this;for(var d in b)if(b[z](d)&&!(d in a))switch(typeof b[d]){case "function":(function(f){a[d]=a===c?f:function(){return f[K](c,arguments)}})(b[d]);break;case "object":a[d]=a[d]||{};Fa.call(this,a[d],b[d]);break;default:a[d]=b[d];break}}function ia(a,b){a==b.top&&(b.top=a.prev);a==b.bottom&&(b.bottom=a.next);a.next&&(a.next.prev=a.prev);a.prev&&(a.prev.next=a.next)}function Ta(a,b){if(b.top!==a){ia(a,b);a.next=null;a.prev=b.top;b.top.next=a;b.top=
a}}function Ua(a,b){if(b.bottom!==a){ia(a,b);a.next=b.bottom;a.prev=null;b.bottom.prev=a;b.bottom=a}}function Va(a,b,c){ia(a,c);b==c.top&&(c.top=a);b.next&&(b.next.prev=a);a.next=b.next;a.prev=b;b.next=a}function Wa(a,b,c){ia(a,c);b==c.bottom&&(c.bottom=a);b.prev&&(b.prev.next=a);a.prev=b.prev;b.prev=a;a.next=b}function Xa(a){return function(){throw new Error("Rapha\u00ebl: you are calling to method \u201c"+a+"\u201d of removed object");}}var Ya=/^r(?:\(([^,]+?)\s*,\s*([^\)]+?)\))?/;if(m.svg){G[p].svgns=
"http://www.w3.org/2000/svg";G[p].xlink="http://www.w3.org/1999/xlink";F=function(a){return+a+(~~a===a)*0.5};var v=function(a,b){if(b)for(var c in b)b[z](c)&&a[W](c,b[c]+s);else{a=C.createElementNS(G[p].svgns,a);a.style.webkitTapHighlightColor="rgba(0,0,0,0)";return a}};m[N]=function(){return"Your browser supports SVG.\nYou are running Rapha\u00ebl "+this.version};var Za=function(a,b){var c=v("path");b.canvas&&b.canvas[y](c);b=new u(c,b);b.type="path";ba(b,{fill:"none",stroke:"#000",path:a});return b},
ma=function(a,b,c){var d="linear",f=0.5,e=0.5,g=a.style;b=(b+s)[I](Ya,function(l,n,r){d="radial";if(n&&r){f=A(n);e=A(r);l=(e>0.5)*2-1;D(f-0.5,2)+D(e-0.5,2)>0.25&&(e=w.sqrt(0.25-D(f-0.5,2))*l+0.5)&&e!=0.5&&(e=e.toFixed(5)-1.0E-5*l)}return s});b=b[H](/\s*\-\s*/);if(d=="linear"){var h=b.shift();h=-A(h);if(isNaN(h))return null;h=[0,0,w.cos(h*w.PI/180),w.sin(h*w.PI/180)];var i=1/(Y(w.abs(h[2]),w.abs(h[3]))||1);h[2]*=i;h[3]*=i;if(h[2]<0){h[0]=-h[2];h[2]=0}if(h[3]<0){h[1]=-h[3];h[3]=0}}b=Ra(b);if(!b)return null;
i=a.getAttribute(aa);(i=i.match(/^url\(#(.*)\)$/))&&c.defs.removeChild(C.getElementById(i[1]));i=v(d+"Gradient");i.id="r"+(m._id++)[N](36);v(i,d=="radial"?{fx:f,fy:e}:{x1:h[0],y1:h[1],x2:h[2],y2:h[3]});c.defs[y](i);c=0;for(h=b[o];c<h;c++){var j=v("stop");v(j,{offset:b[c].offset?b[c].offset:!c?"0%":"100%","stop-color":b[c].color||"#fff"});i[y](j)}v(a,{fill:"url(#"+i.id+")",opacity:1,"fill-opacity":1});g.fill=s;g.opacity=1;return g.fillOpacity=1},Ga=function(a){var b=a.getBBox();v(a.pattern,{patternTransform:m.format("translate({0},{1})",
b.x,b.y)})},ba=function(a,b){var c={"":[0],none:[0],"-":[3,1],".":[1,1],"-.":[3,1,1,1],"-..":[3,1,1,1,1,1],". ":[1,3],"- ":[4,3],"--":[8,3],"- .":[4,3,1,3],"--.":[8,3,1,3],"--..":[8,3,1,3,1,3]},d=a.node,f=a.attrs,e=a.rotate();function g(k,t){if(t=c[ca.call(t)]){var L=k.attrs["stroke-width"]||"1";k={round:L,square:L,butt:0}[k.attrs["stroke-linecap"]||b["stroke-linecap"]]||0;for(var B=[],x=t[o];x--;)B[x]=t[x]*L+(x%2?1:-1)*k;v(d,{"stroke-dasharray":B[Q](",")})}}b[z]("rotation")&&(e=b.rotation);var h=
(e+s)[H](V);if(h.length-1){h[1]=+h[1];h[2]=+h[2]}else h=null;A(e)&&a.rotate(0,true);for(var i in b)if(b[z](i))if(qa[z](i)){var j=b[i];f[i]=j;switch(i){case "blur":a.blur(j);break;case "rotation":a.rotate(j,true);break;case "href":case "title":case "target":var l=d.parentNode;if(ca.call(l.tagName)!="a"){var n=v("a");l.insertBefore(n,d);n[y](d);l=n}l.setAttributeNS(a.paper.xlink,i,j);break;case "cursor":d.style.cursor=j;break;case "clip-rect":l=(j+s)[H](V);if(l[o]==4){a.clip&&a.clip.parentNode.parentNode.removeChild(a.clip.parentNode);
var r=v("clipPath");n=v("rect");r.id="r"+(m._id++)[N](36);v(n,{x:l[0],y:l[1],width:l[2],height:l[3]});r[y](n);a.paper.defs[y](r);v(d,{"clip-path":"url(#"+r.id+")"});a.clip=n}if(!j){(j=C.getElementById(d.getAttribute("clip-path")[I](/(^url\(#|\)$)/g,s)))&&j.parentNode.removeChild(j);v(d,{"clip-path":s});delete a.clip}break;case "path":if(a.type=="path")v(d,{d:j?(f.path=ka(j)):"M0,0"});break;case "width":d[W](i,j);if(f.fx){i="x";j=f.x}else break;case "x":if(f.fx)j=-f.x-(f.width||0);case "rx":if(i==
"rx"&&a.type=="rect")break;case "cx":h&&(i=="x"||i=="cx")&&(h[1]+=j-f[i]);d[W](i,F(j));a.pattern&&Ga(a);break;case "height":d[W](i,j);if(f.fy){i="y";j=f.y}else break;case "y":if(f.fy)j=-f.y-(f.height||0);case "ry":if(i=="ry"&&a.type=="rect")break;case "cy":h&&(i=="y"||i=="cy")&&(h[2]+=j-f[i]);d[W](i,F(j));a.pattern&&Ga(a);break;case "r":a.type=="rect"?v(d,{rx:j,ry:j}):d[W](i,j);break;case "src":a.type=="image"&&d.setAttributeNS(a.paper.xlink,"href",j);break;case "stroke-width":d.style.strokeWidth=
j;d[W](i,j);f["stroke-dasharray"]&&g(a,f["stroke-dasharray"]);break;case "stroke-dasharray":g(a,j);break;case "translation":j=(j+s)[H](V);j[0]=+j[0]||0;j[1]=+j[1]||0;if(h){h[1]+=j[0];h[2]+=j[1]}ya.call(a,j[0],j[1]);break;case "scale":j=(j+s)[H](V);a.scale(+j[0]||1,+j[1]||+j[0]||1,isNaN(A(j[2]))?null:+j[2],isNaN(A(j[3]))?null:+j[3]);break;case aa:if(l=(j+s).match(Na)){r=v("pattern");var q=v("image");r.id="r"+(m._id++)[N](36);v(r,{x:0,y:0,patternUnits:"userSpaceOnUse",height:1,width:1});v(q,{x:0,y:0});
q.setAttributeNS(a.paper.xlink,"href",l[1]);r[y](q);j=C.createElement("img");j.style.cssText="position:absolute;left:-9999em;top-9999em";j.onload=function(){v(r,{width:this.offsetWidth,height:this.offsetHeight});v(q,{width:this.offsetWidth,height:this.offsetHeight});C.body.removeChild(this);a.paper.safari()};C.body[y](j);j.src=l[1];a.paper.defs[y](r);d.style.fill="url(#"+r.id+")";v(d,{fill:"url(#"+r.id+")"});a.pattern=r;a.pattern&&Ga(a);break}l=m.getRGB(j);if(l.error){if(({circle:1,ellipse:1}[z](a.type)||
(j+s).charAt()!="r")&&ma(d,j,a.paper)){f.gradient=j;f.fill="none";break}}else{delete b.gradient;delete f.gradient;!m.is(f.opacity,"undefined")&&m.is(b.opacity,"undefined")&&v(d,{opacity:f.opacity});!m.is(f["fill-opacity"],"undefined")&&m.is(b["fill-opacity"],"undefined")&&v(d,{"fill-opacity":f["fill-opacity"]})}l[z]("o")&&v(d,{"fill-opacity":l.o/100});case "stroke":l=m.getRGB(j);d[W](i,l.hex);i=="stroke"&&l[z]("o")&&v(d,{"stroke-opacity":l.o/100});break;case "gradient":(({circle:1,ellipse:1})[z](a.type)||
(j+s).charAt()!="r")&&ma(d,j,a.paper);break;case "opacity":case "fill-opacity":if(f.gradient){if(l=C.getElementById(d.getAttribute(aa)[I](/^url\(#|\)$/g,s))){l=l.getElementsByTagName("stop");l[l[o]-1][W]("stop-opacity",j)}break}default:i=="font-size"&&(j=da(j,10)+"px");l=i[I](/(\-.)/g,function(k){return pa.call(k.substring(1))});d.style[l]=j;d[W](i,j);break}}yb(a,b);if(h)a.rotate(h.join(P));else A(e)&&a.rotate(e,true)},$a=1.2,yb=function(a,b){if(!(a.type!="text"||!(b[z]("text")||b[z]("font")||b[z]("font-size")||
b[z]("x")||b[z]("y")))){var c=a.attrs,d=a.node,f=d.firstChild?da(C.defaultView.getComputedStyle(d.firstChild,s).getPropertyValue("font-size"),10):10;if(b[z]("text")){for(c.text=b.text;d.firstChild;)d.removeChild(d.firstChild);b=(b.text+s)[H]("\n");for(var e=0,g=b[o];e<g;e++)if(b[e]){var h=v("tspan");e&&v(h,{dy:f*$a,x:c.x});h[y](C.createTextNode(b[e]));d[y](h)}}else{b=d.getElementsByTagName("tspan");e=0;for(g=b[o];e<g;e++)e&&v(b[e],{dy:f*$a,x:c.x})}v(d,{y:c.y});a=a.getBBox();(a=c.y-(a.y+a.height/2))&&
isFinite(a)&&v(d,{y:c.y+a})}},u=function(a,b){this[0]=a;this.id=m._oid++;this.node=a;a.raphael=this;this.paper=b;this.attrs=this.attrs||{};this.transformations=[];this._={tx:0,ty:0,rt:{deg:0,cx:0,cy:0},sx:1,sy:1};!b.bottom&&(b.bottom=this);(this.prev=b.top)&&(b.top.next=this);b.top=this;this.next=null};u[p].rotate=function(a,b,c){if(this.removed)return this;if(a==null){if(this._.rt.cx)return[this._.rt.deg,this._.rt.cx,this._.rt.cy][Q](P);return this._.rt.deg}var d=this.getBBox();a=(a+s)[H](V);if(a[o]-
1){b=A(a[1]);c=A(a[2])}a=A(a[0]);if(b!=null)this._.rt.deg=a;else this._.rt.deg+=a;c==null&&(b=null);this._.rt.cx=b;this._.rt.cy=c;b=b==null?d.x+d.width/2:b;c=c==null?d.y+d.height/2:c;if(this._.rt.deg){this.transformations[0]=m.format("rotate({0} {1} {2})",this._.rt.deg,b,c);this.clip&&v(this.clip,{transform:m.format("rotate({0} {1} {2})",-this._.rt.deg,b,c)})}else{this.transformations[0]=s;this.clip&&v(this.clip,{transform:s})}v(this.node,{transform:this.transformations[Q](P)});return this};u[p].hide=
function(){!this.removed&&(this.node.style.display="none");return this};u[p].show=function(){!this.removed&&(this.node.style.display="");return this};u[p].remove=function(){if(!this.removed){ia(this,this.paper);this.node.parentNode.removeChild(this.node);for(var a in this)delete this[a];this.removed=true}};u[p].getBBox=function(){if(this.removed)return this;if(this.type=="path")return va(this.attrs.path);if(this.node.style.display=="none"){this.show();var a=true}var b={};try{b=this.node.getBBox()}catch(c){}finally{b=
b||{}}if(this.type=="text"){b={x:b.x,y:Infinity,width:0,height:0};for(var d=0,f=this.node.getNumberOfChars();d<f;d++){var e=this.node.getExtentOfChar(d);e.y<b.y&&(b.y=e.y);e.y+e.height-b.y>b.height&&(b.height=e.y+e.height-b.y);e.x+e.width-b.x>b.width&&(b.width=e.x+e.width-b.x)}}a&&this.hide();return b};u[p].attr=function(a,b){if(this.removed)return this;if(a==null){a={};for(var c in this.attrs)if(this.attrs[z](c))a[c]=this.attrs[c];this._.rt.deg&&(a.rotation=this.rotate());(this._.sx!=1||this._.sy!=
1)&&(a.scale=this.scale());a.gradient&&a.fill=="none"&&(a.fill=a.gradient)&&delete a.gradient;return a}if(b==null&&m.is(a,ea)){if(a=="translation")return ya.call(this);if(a=="rotation")return this.rotate();if(a=="scale")return this.scale();if(a==aa&&this.attrs.fill=="none"&&this.attrs.gradient)return this.attrs.gradient;return this.attrs[a]}if(b==null&&m.is(a,U)){b={};c=0;for(var d=a.length;c<d;c++)b[a[c]]=this.attr(a[c]);return b}if(b!=null){c={};c[a]=b;ba(this,c)}else a!=null&&m.is(a,"object")&&
ba(this,a);return this};u[p].toFront=function(){if(this.removed)return this;this.node.parentNode[y](this.node);var a=this.paper;a.top!=this&&Ta(this,a);return this};u[p].toBack=function(){if(this.removed)return this;if(this.node.parentNode.firstChild!=this.node){this.node.parentNode.insertBefore(this.node,this.node.parentNode.firstChild);Ua(this,this.paper)}return this};u[p].insertAfter=function(a){if(this.removed)return this;var b=a.node;b.nextSibling?b.parentNode.insertBefore(this.node,b.nextSibling):
b.parentNode[y](this.node);Va(this,a,this.paper);return this};u[p].insertBefore=function(a){if(this.removed)return this;var b=a.node;b.parentNode.insertBefore(this.node,b);Wa(this,a,this.paper);return this};u[p].blur=function(a){var b=this;if(+a!==0){var c=v("filter"),d=v("feGaussianBlur");b.attrs.blur=a;c.id="r"+(m._id++)[N](36);v(d,{stdDeviation:+a||1.5});c.appendChild(d);b.paper.defs.appendChild(c);b._blur=c;v(b.node,{filter:"url(#"+c.id+")"})}else{if(b._blur){b._blur.parentNode.removeChild(b._blur);
delete b._blur;delete b.attrs.blur}b.node.removeAttribute("filter")}};var ab=function(a,b,c,d){b=F(b);c=F(c);var f=v("circle");a.canvas&&a.canvas[y](f);a=new u(f,a);a.attrs={cx:b,cy:c,r:d,fill:"none",stroke:"#000"};a.type="circle";v(f,a.attrs);return a},bb=function(a,b,c,d,f,e){b=F(b);c=F(c);var g=v("rect");a.canvas&&a.canvas[y](g);a=new u(g,a);a.attrs={x:b,y:c,width:d,height:f,r:e||0,rx:e||0,ry:e||0,fill:"none",stroke:"#000"};a.type="rect";v(g,a.attrs);return a},cb=function(a,b,c,d,f){b=F(b);c=F(c);
var e=v("ellipse");a.canvas&&a.canvas[y](e);a=new u(e,a);a.attrs={cx:b,cy:c,rx:d,ry:f,fill:"none",stroke:"#000"};a.type="ellipse";v(e,a.attrs);return a},db=function(a,b,c,d,f,e){var g=v("image");v(g,{x:c,y:d,width:f,height:e,preserveAspectRatio:"none"});g.setAttributeNS(a.xlink,"href",b);a.canvas&&a.canvas[y](g);a=new u(g,a);a.attrs={x:c,y:d,width:f,height:e,src:b};a.type="image";return a},eb=function(a,b,c,d){var f=v("text");v(f,{x:b,y:c,"text-anchor":"middle"});a.canvas&&a.canvas[y](f);a=new u(f,
a);a.attrs={x:b,y:c,"text-anchor":"middle",text:d,font:qa.font,stroke:"none",fill:"#000"};a.type="text";ba(a,a.attrs);return a},fb=function(a,b){this.width=a||this.width;this.height=b||this.height;this.canvas[W]("width",this.width);this.canvas[W]("height",this.height);return this},Aa=function(){var a=Sa[K](0,arguments),b=a&&a.container,c=a.x,d=a.y,f=a.width;a=a.height;if(!b)throw new Error("SVG container not found.");var e=v("svg");c=c||0;d=d||0;f=f||512;a=a||342;v(e,{xmlns:"http://www.w3.org/2000/svg",
version:1.1,width:f,height:a});if(b==1){e.style.cssText="position:absolute;left:"+c+"px;top:"+d+"px";C.body[y](e)}else b.firstChild?b.insertBefore(e,b.firstChild):b[y](e);b=new G;b.width=f;b.height=a;b.canvas=e;Fa.call(b,b,m.fn);b.clear();return b};G[p].clear=function(){for(var a=this.canvas;a.firstChild;)a.removeChild(a.firstChild);this.bottom=this.top=null;(this.desc=v("desc"))[y](C.createTextNode("Created with Rapha\u00ebl"));a[y](this.desc);a[y](this.defs=v("defs"))};G[p].remove=function(){this.canvas.parentNode&&
this.canvas.parentNode.removeChild(this.canvas);for(var a in this)this[a]=Xa(a)}}if(m.vml){var gb={M:"m",L:"l",C:"c",Z:"x",m:"t",l:"r",c:"v",z:"x"},zb=/([clmz]),?([^clmz]*)/gi,Ab=/-?[^,\s-]+/g,na=1000+P+1000,ja=10,oa={path:1,rect:1},Bb=function(a){var b=/[ahqstv]/ig,c=ka;(a+s).match(b)&&(c=ua);b=/[clmz]/g;if(c==ka&&!(a+s).match(b))return a=(a+s)[I](zb,function(i,j,l){var n=[],r=ca.call(j)=="m",q=gb[j];l[I](Ab,function(k){if(r&&n[o]==2){q+=n+gb[j=="m"?"l":"L"];n=[]}n[E](F(k*ja))});return q+n});b=c(a);
var d;a=[];for(var f=0,e=b[o];f<e;f++){c=b[f];d=ca.call(b[f][0]);d=="z"&&(d="x");for(var g=1,h=c[o];g<h;g++)d+=F(c[g]*ja)+(g!=h-1?",":s);a[E](d)}return a[Q](P)};m[N]=function(){return"Your browser doesn\u2019t support SVG. Falling down to VML.\nYou are running Rapha\u00ebl "+this.version};Za=function(a,b){var c=R("group");c.style.cssText="position:absolute;left:0;top:0;width:"+b.width+"px;height:"+b.height+"px";c.coordsize=b.coordsize;c.coordorigin=b.coordorigin;var d=R("shape"),f=d.style;f.width=
b.width+"px";f.height=b.height+"px";d.coordsize=na;d.coordorigin=b.coordorigin;c[y](d);d=new u(d,c,b);f={fill:"none",stroke:"#000"};a&&(f.path=a);d.isAbsolute=true;d.type="path";d.path=[];d.Path=s;ba(d,f);b.canvas[y](c);return d};ba=function(a,b){a.attrs=a.attrs||{};var c=a.node,d=a.attrs,f=c.style,e;e=(b.x!=d.x||b.y!=d.y||b.width!=d.width||b.height!=d.height||b.r!=d.r)&&a.type=="rect";var g=a;for(var h in b)if(b[z](h))d[h]=b[h];if(e){d.path=hb(d.x,d.y,d.width,d.height,d.r);a.X=d.x;a.Y=d.y;a.W=d.width;
a.H=d.height}b.href&&(c.href=b.href);b.title&&(c.title=b.title);b.target&&(c.target=b.target);b.cursor&&(f.cursor=b.cursor);"blur"in b&&a.blur(b.blur);if(b.path&&a.type=="path"||e)c.path=Bb(d.path);b.rotation!=null&&a.rotate(b.rotation,true);if(b.translation){e=(b.translation+s)[H](V);ya.call(a,e[0],e[1]);if(a._.rt.cx!=null){a._.rt.cx+=+e[0];a._.rt.cy+=+e[1];a.setBox(a.attrs,e[0],e[1])}}if(b.scale){e=(b.scale+s)[H](V);a.scale(+e[0]||1,+e[1]||+e[0]||1,+e[2]||null,+e[3]||null)}if("clip-rect"in b){e=
(b["clip-rect"]+s)[H](V);if(e[o]==4){e[2]=+e[2]+ +e[0];e[3]=+e[3]+ +e[1];h=c.clipRect||C.createElement("div");var i=h.style,j=c.parentNode;i.clip=m.format("rect({1}px {2}px {3}px {0}px)",e);if(!c.clipRect){i.position="absolute";i.top=0;i.left=0;i.width=a.paper.width+"px";i.height=a.paper.height+"px";j.parentNode.insertBefore(h,j);h[y](j);c.clipRect=h}}if(!b["clip-rect"])c.clipRect&&(c.clipRect.style.clip=s)}if(a.type=="image"&&b.src)c.src=b.src;if(a.type=="image"&&b.opacity){c.filterOpacity=Da+".Alpha(opacity="+
b.opacity*100+")";f.filter=(c.filterMatrix||s)+(c.filterOpacity||s)}b.font&&(f.font=b.font);b["font-family"]&&(f.fontFamily='"'+b["font-family"][H](",")[0][I](/^['"]+|['"]+$/g,s)+'"');b["font-size"]&&(f.fontSize=b["font-size"]);b["font-weight"]&&(f.fontWeight=b["font-weight"]);b["font-style"]&&(f.fontStyle=b["font-style"]);if(b.opacity!=null||b["stroke-width"]!=null||b.fill!=null||b.stroke!=null||b["stroke-width"]!=null||b["stroke-opacity"]!=null||b["fill-opacity"]!=null||b["stroke-dasharray"]!=null||
b["stroke-miterlimit"]!=null||b["stroke-linejoin"]!=null||b["stroke-linecap"]!=null){c=a.shape||c;f=c.getElementsByTagName(aa)&&c.getElementsByTagName(aa)[0];e=false;!f&&(e=f=R(aa));if("fill-opacity"in b||"opacity"in b){a=((+d["fill-opacity"]+1||2)-1)*((+d.opacity+1||2)-1)*((+m.getRGB(b.fill).o+1||2)-1);a<0&&(a=0);a>1&&(a=1);f.opacity=a}b.fill&&(f.on=true);if(f.on==null||b.fill=="none")f.on=false;if(f.on&&b.fill)if(a=b.fill.match(Na)){f.src=a[1];f.type="tile"}else{f.color=m.getRGB(b.fill).hex;f.src=
s;f.type="solid";if(m.getRGB(b.fill).error&&(g.type in{circle:1,ellipse:1}||(b.fill+s).charAt()!="r")&&ma(g,b.fill)){d.fill="none";d.gradient=b.fill}}e&&c[y](f);f=c.getElementsByTagName("stroke")&&c.getElementsByTagName("stroke")[0];e=false;!f&&(e=f=R("stroke"));if(b.stroke&&b.stroke!="none"||b["stroke-width"]||b["stroke-opacity"]!=null||b["stroke-dasharray"]||b["stroke-miterlimit"]||b["stroke-linejoin"]||b["stroke-linecap"])f.on=true;(b.stroke=="none"||f.on==null||b.stroke==0||b["stroke-width"]==
0)&&(f.on=false);a=m.getRGB(b.stroke);f.on&&b.stroke&&(f.color=a.hex);a=((+d["stroke-opacity"]+1||2)-1)*((+d.opacity+1||2)-1)*((+a.o+1||2)-1);h=(A(b["stroke-width"])||1)*0.75;a<0&&(a=0);a>1&&(a=1);b["stroke-width"]==null&&(h=d["stroke-width"]);b["stroke-width"]&&(f.weight=h);h&&h<1&&(a*=h)&&(f.weight=1);f.opacity=a;b["stroke-linejoin"]&&(f.joinstyle=b["stroke-linejoin"]||"miter");f.miterlimit=b["stroke-miterlimit"]||8;b["stroke-linecap"]&&(f.endcap=b["stroke-linecap"]=="butt"?"flat":b["stroke-linecap"]==
"square"?"square":"round");if(b["stroke-dasharray"]){a={"-":"shortdash",".":"shortdot","-.":"shortdashdot","-..":"shortdashdotdot",". ":"dot","- ":"dash","--":"longdash","- .":"dashdot","--.":"longdashdot","--..":"longdashdotdot"};f.dashstyle=a[z](b["stroke-dasharray"])?a[b["stroke-dasharray"]]:s}e&&c[y](f)}if(g.type=="text"){f=g.paper.span.style;d.font&&(f.font=d.font);d["font-family"]&&(f.fontFamily=d["font-family"]);d["font-size"]&&(f.fontSize=d["font-size"]);d["font-weight"]&&(f.fontWeight=d["font-weight"]);
d["font-style"]&&(f.fontStyle=d["font-style"]);g.node.string&&(g.paper.span.innerHTML=(g.node.string+s)[I](/</g,"&#60;")[I](/&/g,"&#38;")[I](/\n/g,"<br>"));g.W=d.w=g.paper.span.offsetWidth;g.H=d.h=g.paper.span.offsetHeight;g.X=d.x;g.Y=d.y+F(g.H/2);switch(d["text-anchor"]){case "start":g.node.style["v-text-align"]="left";g.bbx=F(g.W/2);break;case "end":g.node.style["v-text-align"]="right";g.bbx=-F(g.W/2);break;default:g.node.style["v-text-align"]="center";break}}};ma=function(a,b){a.attrs=a.attrs||
{};var c="linear",d=".5 .5";a.attrs.gradient=b;b=(b+s)[I](Ya,function(i,j,l){c="radial";if(j&&l){j=A(j);l=A(l);D(j-0.5,2)+D(l-0.5,2)>0.25&&(l=w.sqrt(0.25-D(j-0.5,2))*((l>0.5)*2-1)+0.5);d=j+P+l}return s});b=b[H](/\s*\-\s*/);if(c=="linear"){var f=b.shift();f=-A(f);if(isNaN(f))return null}var e=Ra(b);if(!e)return null;a=a.shape||a.node;b=a.getElementsByTagName(aa)[0]||R(aa);!b.parentNode&&a.appendChild(b);if(e[o]){b.on=true;b.method="none";b.color=e[0].color;b.color2=e[e[o]-1].color;a=[];for(var g=0,
h=e[o];g<h;g++)e[g].offset&&a[E](e[g].offset+P+e[g].color);b.colors&&(b.colors.value=a[o]?a[Q]():"0% "+b.color);if(c=="radial"){b.type="gradientradial";b.focus="100%";b.focussize=d;b.focusposition=d}else{b.type="gradient";b.angle=(270-f)%360}}return 1};u=function(a,b,c){this[0]=a;this.id=m._oid++;this.node=a;a.raphael=this;this.Y=this.X=0;this.attrs={};this.Group=b;this.paper=c;this._={tx:0,ty:0,rt:{deg:0},sx:1,sy:1};!c.bottom&&(c.bottom=this);(this.prev=c.top)&&(c.top.next=this);c.top=this;this.next=
null};u[p].rotate=function(a,b,c){if(this.removed)return this;if(a==null){if(this._.rt.cx)return[this._.rt.deg,this._.rt.cx,this._.rt.cy][Q](P);return this._.rt.deg}a=(a+s)[H](V);if(a[o]-1){b=A(a[1]);c=A(a[2])}a=A(a[0]);if(b!=null)this._.rt.deg=a;else this._.rt.deg+=a;c==null&&(b=null);this._.rt.cx=b;this._.rt.cy=c;this.setBox(this.attrs,b,c);this.Group.style.rotation=this._.rt.deg;return this};u[p].setBox=function(a,b,c){if(this.removed)return this;var d=this.Group.style,f=this.shape&&this.shape.style||
this.node.style;a=a||{};for(var e in a)if(a[z](e))this.attrs[e]=a[e];b=b||this._.rt.cx;c=c||this._.rt.cy;var g=this.attrs,h;switch(this.type){case "circle":a=g.cx-g.r;e=g.cy-g.r;h=g=g.r*2;break;case "ellipse":a=g.cx-g.rx;e=g.cy-g.ry;h=g.rx*2;g=g.ry*2;break;case "image":a=+g.x;e=+g.y;h=g.width||0;g=g.height||0;break;case "text":this.textpath.v=["m",F(g.x),", ",F(g.y-2),"l",F(g.x)+1,", ",F(g.y-2)][Q](s);a=g.x-F(this.W/2);e=g.y-this.H/2;h=this.W;g=this.H;break;case "rect":case "path":if(this.attrs.path){g=
va(this.attrs.path);a=g.x;e=g.y;h=g.width;g=g.height}else{e=a=0;h=this.paper.width;g=this.paper.height}break;default:e=a=0;h=this.paper.width;g=this.paper.height;break}b=b==null?a+h/2:b;c=c==null?e+g/2:c;b=b-this.paper.width/2;c=c-this.paper.height/2;var i;d.left!=(i=b+"px")&&(d.left=i);d.top!=(i=c+"px")&&(d.top=i);this.X=oa[z](this.type)?-b:a;this.Y=oa[z](this.type)?-c:e;this.W=h;this.H=g;if(oa[z](this.type)){f.left!=(i=-b*ja+"px")&&(f.left=i);f.top!=(i=-c*ja+"px")&&(f.top=i)}else if(this.type==
"text"){f.left!=(i=-b+"px")&&(f.left=i);f.top!=(i=-c+"px")&&(f.top=i)}else{d.width!=(i=this.paper.width+"px")&&(d.width=i);d.height!=(i=this.paper.height+"px")&&(d.height=i);f.left!=(i=a-b+"px")&&(f.left=i);f.top!=(i=e-c+"px")&&(f.top=i);f.width!=(i=h+"px")&&(f.width=i);f.height!=(i=g+"px")&&(f.height=i)}};u[p].hide=function(){!this.removed&&(this.Group.style.display="none");return this};u[p].show=function(){!this.removed&&(this.Group.style.display="block");return this};u[p].getBBox=function(){if(this.removed)return this;
if(oa[z](this.type))return va(this.attrs.path);return{x:this.X+(this.bbx||0),y:this.Y,width:this.W,height:this.H}};u[p].remove=function(){if(!this.removed){ia(this,this.paper);this.node.parentNode.removeChild(this.node);this.Group.parentNode.removeChild(this.Group);this.shape&&this.shape.parentNode.removeChild(this.shape);for(var a in this)delete this[a];this.removed=true}};u[p].attr=function(a,b){if(this.removed)return this;if(a==null){a={};for(var c in this.attrs)if(this.attrs[z](c))a[c]=this.attrs[c];
this._.rt.deg&&(a.rotation=this.rotate());(this._.sx!=1||this._.sy!=1)&&(a.scale=this.scale());a.gradient&&a.fill=="none"&&(a.fill=a.gradient)&&delete a.gradient;return a}if(b==null&&m.is(a,ea)){if(a=="translation")return ya.call(this);if(a=="rotation")return this.rotate();if(a=="scale")return this.scale();if(a==aa&&this.attrs.fill=="none"&&this.attrs.gradient)return this.attrs.gradient;return this.attrs[a]}if(this.attrs&&b==null&&m.is(a,U)){var d={};c=0;for(b=a[o];c<b;c++)d[a[c]]=this.attr(a[c]);
return d}if(b!=null){d={};d[a]=b}b==null&&m.is(a,"object")&&(d=a);if(d){if(d.text&&this.type=="text")this.node.string=d.text;ba(this,d);if(d.gradient&&({circle:1,ellipse:1}[z](this.type)||(d.gradient+s).charAt()!="r"))ma(this,d.gradient);(!oa[z](this.type)||this._.rt.deg)&&this.setBox(this.attrs)}return this};u[p].toFront=function(){!this.removed&&this.Group.parentNode[y](this.Group);this.paper.top!=this&&Ta(this,this.paper);return this};u[p].toBack=function(){if(this.removed)return this;if(this.Group.parentNode.firstChild!=
this.Group){this.Group.parentNode.insertBefore(this.Group,this.Group.parentNode.firstChild);Ua(this,this.paper)}return this};u[p].insertAfter=function(a){if(this.removed)return this;a.Group.nextSibling?a.Group.parentNode.insertBefore(this.Group,a.Group.nextSibling):a.Group.parentNode[y](this.Group);Va(this,a,this.paper);return this};u[p].insertBefore=function(a){if(this.removed)return this;a.Group.parentNode.insertBefore(this.Group,a.Group);Wa(this,a,this.paper);return this};var Cb=/ progid:\S+Blur\([^\)]+\)/g;
u[p].blur=function(a){var b=this.node.style,c=b.filter;c=c.replace(Cb,"");if(+a!==0){this.attrs.blur=a;b.filter=c+Da+".Blur(pixelradius="+(+a||1.5)+")";b.margin=Raphael.format("-{0}px 0 0 -{0}px",Math.round(+a||1.5))}else{b.filter=c;b.margin=0;delete this.attrs.blur}};ab=function(a,b,c,d){var f=R("group"),e=R("oval");f.style.cssText="position:absolute;left:0;top:0;width:"+a.width+"px;height:"+a.height+"px";f.coordsize=na;f.coordorigin=a.coordorigin;f[y](e);e=new u(e,f,a);e.type="circle";ba(e,{stroke:"#000",
fill:"none"});e.attrs.cx=b;e.attrs.cy=c;e.attrs.r=d;e.setBox({x:b-d,y:c-d,width:d*2,height:d*2});a.canvas[y](f);return e};function hb(a,b,c,d,f){return f?m.format("M{0},{1}l{2},0a{3},{3},0,0,1,{3},{3}l0,{5}a{3},{3},0,0,1,{4},{3}l{6},0a{3},{3},0,0,1,{4},{4}l0,{7}a{3},{3},0,0,1,{3},{4}z",a+f,b,c-f*2,f,-f,d-f*2,f*2-c,f*2-d):m.format("M{0},{1}l{2},0,0,{3},{4},0z",a,b,c,d,-c)}bb=function(a,b,c,d,f,e){var g=hb(b,c,d,f,e);a=a.path(g);var h=a.attrs;a.X=h.x=b;a.Y=h.y=c;a.W=h.width=d;a.H=h.height=f;h.r=e;h.path=
g;a.type="rect";return a};cb=function(a,b,c,d,f){var e=R("group"),g=R("oval");e.style.cssText="position:absolute;left:0;top:0;width:"+a.width+"px;height:"+a.height+"px";e.coordsize=na;e.coordorigin=a.coordorigin;e[y](g);g=new u(g,e,a);g.type="ellipse";ba(g,{stroke:"#000"});g.attrs.cx=b;g.attrs.cy=c;g.attrs.rx=d;g.attrs.ry=f;g.setBox({x:b-d,y:c-f,width:d*2,height:f*2});a.canvas[y](e);return g};db=function(a,b,c,d,f,e){var g=R("group"),h=R("image");g.style.cssText="position:absolute;left:0;top:0;width:"+
a.width+"px;height:"+a.height+"px";g.coordsize=na;g.coordorigin=a.coordorigin;h.src=b;g[y](h);h=new u(h,g,a);h.type="image";h.attrs.src=b;h.attrs.x=c;h.attrs.y=d;h.attrs.w=f;h.attrs.h=e;h.setBox({x:c,y:d,width:f,height:e});a.canvas[y](g);return h};eb=function(a,b,c,d){var f=R("group"),e=R("shape"),g=e.style,h=R("path"),i=R("textpath");f.style.cssText="position:absolute;left:0;top:0;width:"+a.width+"px;height:"+a.height+"px";f.coordsize=na;f.coordorigin=a.coordorigin;h.v=m.format("m{0},{1}l{2},{1}",
F(b*10),F(c*10),F(b*10)+1);h.textpathok=true;g.width=a.width;g.height=a.height;i.string=d+s;i.on=true;e[y](i);e[y](h);f[y](e);g=new u(i,f,a);g.shape=e;g.textpath=h;g.type="text";g.attrs.text=d;g.attrs.x=b;g.attrs.y=c;g.attrs.w=1;g.attrs.h=1;ba(g,{font:qa.font,stroke:"none",fill:"#000"});g.setBox();a.canvas[y](f);return g};fb=function(a,b){var c=this.canvas.style;a==+a&&(a+="px");b==+b&&(b+="px");c.width=a;c.height=b;c.clip="rect(0 "+a+" "+b+" 0)";return this};var R;C.createStyleSheet().addRule(".rvml",
"behavior:url(#default#VML)");try{!C.namespaces.rvml&&C.namespaces.add("rvml","urn:schemas-microsoft-com:vml");R=function(a){return C.createElement("<rvml:"+a+' class="rvml">')}}catch(Kb){R=function(a){return C.createElement("<"+a+' xmlns="urn:schemas-microsoft.com:vml" class="rvml">')}}Aa=function(){var a=Sa[K](0,arguments),b=a.container,c=a.height,d=a.width,f=a.x;a=a.y;if(!b)throw new Error("VML container not found.");var e=new G,g=e.canvas=C.createElement("div"),h=g.style;f=f||0;a=a||0;d=d||512;
c=c||342;d==+d&&(d+="px");c==+c&&(c+="px");e.width=1000;e.height=1000;e.coordsize=ja*1000+P+ja*1000;e.coordorigin="0 0";e.span=C.createElement("span");e.span.style.cssText="position:absolute;left:-9999em;top:-9999em;padding:0;margin:0;line-height:1;display:inline;";g[y](e.span);h.cssText=m.format("width:{0};height:{1};display:inline-block;position:relative;clip:rect(0 {0} {1} 0);overflow:hidden",d,c);if(b==1){C.body[y](g);h.left=f+"px";h.top=a+"px";h.position="absolute"}else b.firstChild?b.insertBefore(g,
b.firstChild):b[y](g);Fa.call(e,e,m.fn);return e};G[p].clear=function(){this.canvas.innerHTML=s;this.span=C.createElement("span");this.span.style.cssText="position:absolute;left:-9999em;top:-9999em;padding:0;margin:0;line-height:1;display:inline;";this.canvas[y](this.span);this.bottom=this.top=null};G[p].remove=function(){this.canvas.parentNode.removeChild(this.canvas);for(var a in this)this[a]=Xa(a);return true}}G[p].safari=/^Apple|^Google/.test(X.navigator.vendor)&&(!(X.navigator.userAgent.indexOf("Version/4.0")+
1)||X.navigator.platform.slice(0,2)=="iP")?function(){var a=this.rect(-99,-99,this.width+99,this.height+99);X.setTimeout(function(){a.remove()})}:function(){};function Db(){this.returnValue=false}function Eb(){return this.originalEvent.preventDefault()}function Fb(){this.cancelBubble=true}function Gb(){return this.originalEvent.stopPropagation()}var Hb=function(){if(C.addEventListener)return function(a,b,c,d){var f=Ba&&Ca[b]?Ca[b]:b;function e(g){if(Ba&&Ca[z](b))for(var h=0,i=g.targetTouches&&g.targetTouches.length;h<
i;h++)if(g.targetTouches[h].target==a){i=g;g=g.targetTouches[h];g.originalEvent=i;g.preventDefault=Eb;g.stopPropagation=Gb;break}return c.call(d,g)}a.addEventListener(f,e,false);return function(){a.removeEventListener(f,e,false);return true}};else if(C.attachEvent)return function(a,b,c,d){function f(g){g=g||X.event;g.preventDefault=g.preventDefault||Db;g.stopPropagation=g.stopPropagation||Fb;return c.call(d,g)}a.attachEvent("on"+b,f);function e(){a.detachEvent("on"+b,f);return true}return e}}();for(ha=
Ma[o];ha--;)(function(a){m[a]=u[p][a]=function(b){if(m.is(b,"function")){this.events=this.events||[];this.events.push({name:a,f:b,unbind:Hb(this.shape||this.node||C,a,b,this)})}return this};m["un"+a]=u[p]["un"+a]=function(b){for(var c=this.events,d=c[o];d--;)if(c[d].name==a&&c[d].f==b){c[d].unbind();c.splice(d,1);!c.length&&delete this.events;return this}return this}})(Ma[ha]);u[p].hover=function(a,b){return this.mouseover(a).mouseout(b)};u[p].unhover=function(a,b){return this.unmouseover(a).unmouseout(b)};
u[p].drag=function(a,b,c){this._drag={};var d=this.mousedown(function(g){(g.originalEvent?g.originalEvent:g).preventDefault();this._drag.x=g.clientX;this._drag.y=g.clientY;this._drag.id=g.identifier;b&&b.call(this,g.clientX,g.clientY);Raphael.mousemove(f).mouseup(e)});function f(g){var h=g.clientX,i=g.clientY;if(Ba)for(var j=g.touches.length,l;j--;){l=g.touches[j];if(l.identifier==d._drag.id){h=l.clientX;i=l.clientY;(g.originalEvent?g.originalEvent:g).preventDefault();break}}else g.preventDefault();
a&&a.call(d,h-d._drag.x,i-d._drag.y,h,i)}function e(){d._drag={};Raphael.unmousemove(f).unmouseup(e);c&&c.call(d)}return this};G[p].circle=function(a,b,c){return ab(this,a||0,b||0,c||0)};G[p].rect=function(a,b,c,d,f){return bb(this,a||0,b||0,c||0,d||0,f||0)};G[p].ellipse=function(a,b,c,d){return cb(this,a||0,b||0,c||0,d||0)};G[p].path=function(a){a&&!m.is(a,ea)&&!m.is(a[0],U)&&(a+=s);return Za(m.format[K](m,arguments),this)};G[p].image=function(a,b,c,d,f){return db(this,a||"about:blank",b||0,c||0,
d||0,f||0)};G[p].text=function(a,b,c){return eb(this,a||0,b||0,c||s)};G[p].set=function(a){arguments[o]>1&&(a=Array[p].splice.call(arguments,0,arguments[o]));return new Z(a)};G[p].setSize=fb;G[p].top=G[p].bottom=null;G[p].raphael=m;function ib(){return this.x+P+this.y}u[p].resetScale=function(){if(this.removed)return this;this._.sx=1;this._.sy=1;this.attrs.scale="1 1"};u[p].scale=function(a,b,c,d){if(this.removed)return this;if(a==null&&b==null)return{x:this._.sx,y:this._.sy,toString:ib};b=b||a;!+b&&
(b=a);var f,e,g=this.attrs;if(a!=0){var h=this.getBBox(),i=h.x+h.width/2,j=h.y+h.height/2;f=a/this._.sx;e=b/this._.sy;c=+c||c==0?c:i;d=+d||d==0?d:j;h=~~(a/w.abs(a));var l=~~(b/w.abs(b)),n=this.node.style,r=c+(i-c)*f;j=d+(j-d)*e;switch(this.type){case "rect":case "image":var q=g.width*h*f,k=g.height*l*e;this.attr({height:k,r:g.r*$(h*f,l*e),width:q,x:r-q/2,y:j-k/2});break;case "circle":case "ellipse":this.attr({rx:g.rx*h*f,ry:g.ry*l*e,r:g.r*$(h*f,l*e),cx:r,cy:j});break;case "text":this.attr({x:r,y:j});
break;case "path":i=Oa(g.path);for(var t=true,L=0,B=i[o];L<B;L++){var x=i[L],J=pa.call(x[0]);if(!(J=="M"&&t)){t=false;if(J=="A"){x[i[L][o]-2]*=f;x[i[L][o]-1]*=e;x[1]*=h*f;x[2]*=l*e;x[5]=+!(h+l?!+x[5]:+x[5])}else if(J=="H"){J=1;for(var fa=x[o];J<fa;J++)x[J]*=f}else if(J=="V"){J=1;for(fa=x[o];J<fa;J++)x[J]*=e}else{J=1;for(fa=x[o];J<fa;J++)x[J]*=J%2?f:e}}}e=va(i);f=r-e.x-e.width/2;e=j-e.y-e.height/2;i[0][1]+=f;i[0][2]+=e;this.attr({path:i});break}if(this.type in{text:1,image:1}&&(h!=1||l!=1))if(this.transformations){this.transformations[2]=
"scale("[M](h,",",l,")");this.node[W]("transform",this.transformations[Q](P));f=h==-1?-g.x-(q||0):g.x;e=l==-1?-g.y-(k||0):g.y;this.attr({x:f,y:e});g.fx=h-1;g.fy=l-1}else{this.node.filterMatrix=Da+".Matrix(M11="[M](h,", M12=0, M21=0, M22=",l,", Dx=0, Dy=0, sizingmethod='auto expand', filtertype='bilinear')");n.filter=(this.node.filterMatrix||s)+(this.node.filterOpacity||s)}else if(this.transformations){this.transformations[2]=s;this.node[W]("transform",this.transformations[Q](P));g.fx=0;g.fy=0}else{this.node.filterMatrix=
s;n.filter=(this.node.filterMatrix||s)+(this.node.filterOpacity||s)}g.scale=[a,b,c,d][Q](P);this._.sx=a;this._.sy=b}return this};u[p].clone=function(){if(this.removed)return null;var a=this.attr();delete a.scale;delete a.translation;return this.paper[this.type]().attr(a)};var jb=T(function(a,b,c,d,f,e,g,h,i){for(var j=0,l,n=0;n<1.001;n+=0.0010){var r=m.findDotsAtSegment(a,b,c,d,f,e,g,h,n);n&&(j+=D(D(l.x-r.x,2)+D(l.y-r.y,2),0.5));if(j>=i)return r;l=r}});function Ha(a,b){return function(c,d,f){c=ua(c);
for(var e,g,h,i,j="",l={},n=0,r=0,q=c.length;r<q;r++){h=c[r];if(h[0]=="M"){e=+h[1];g=+h[2]}else{i=Ib(e,g,h[1],h[2],h[3],h[4],h[5],h[6]);if(n+i>d){if(b&&!l.start){e=jb(e,g,h[1],h[2],h[3],h[4],h[5],h[6],d-n);j+=["C",e.start.x,e.start.y,e.m.x,e.m.y,e.x,e.y];if(f)return j;l.start=j;j=["M",e.x,e.y+"C",e.n.x,e.n.y,e.end.x,e.end.y,h[5],h[6]][Q]();n+=i;e=+h[5];g=+h[6];continue}if(!a&&!b){e=jb(e,g,h[1],h[2],h[3],h[4],h[5],h[6],d-n);return{x:e.x,y:e.y,alpha:e.alpha}}}n+=i;e=+h[5];g=+h[6]}j+=h}l.end=j;e=a?n:
b?l:m.findDotsAtSegment(e,g,h[1],h[2],h[3],h[4],h[5],h[6],1);e.alpha&&(e={x:e.x,y:e.y,alpha:e.alpha});return e}}var Ib=T(function(a,b,c,d,f,e,g,h){for(var i={x:0,y:0},j=0,l=0;l<1.01;l+=0.01){var n=la(a,b,c,d,f,e,g,h,l);l&&(j+=D(D(i.x-n.x,2)+D(i.y-n.y,2),0.5));i=n}return j}),kb=Ha(1),za=Ha(),Ia=Ha(0,1);u[p].getTotalLength=function(){if(this.type=="path"){if(this.node.getTotalLength)return this.node.getTotalLength();return kb(this.attrs.path)}};u[p].getPointAtLength=function(a){if(this.type=="path")return za(this.attrs.path,
a)};u[p].getSubpath=function(a,b){if(this.type=="path"){if(w.abs(this.getTotalLength()-b)<1.0E-6)return Ia(this.attrs.path,a).end;b=Ia(this.attrs.path,b,1);return a?Ia(b,a).end:b}};m.easing_formulas={linear:function(a){return a},"<":function(a){return D(a,3)},">":function(a){return D(a-1,3)+1},"<>":function(a){a*=2;if(a<1)return D(a,3)/2;a-=2;return(D(a,3)+2)/2},backIn:function(a){var b=1.70158;return a*a*((b+1)*a-b)},backOut:function(a){a-=1;var b=1.70158;return a*a*((b+1)*a+b)+1},elastic:function(a){if(a==
0||a==1)return a;var b=0.3,c=b/4;return D(2,-10*a)*w.sin((a-c)*2*w.PI/b)+1},bounce:function(a){var b=7.5625,c=2.75;if(a<1/c)a=b*a*a;else if(a<2/c){a-=1.5/c;a=b*a*a+0.75}else if(a<2.5/c){a-=2.25/c;a=b*a*a+0.9375}else{a-=2.625/c;a=b*a*a+0.984375}return a}};var S={length:0};function lb(){var a=+new Date;for(var b in S)if(b!="length"&&S[z](b)){var c=S[b];if(c.stop||c.el.removed){delete S[b];S[o]--}else{var d=a-c.start,f=c.ms,e=c.easing,g=c.from,h=c.diff,i=c.to,j=c.t,l=c.prev||0,n=c.el,r=c.callback,q=
{},k;if(d<f){r=m.easing_formulas[e]?m.easing_formulas[e](d/f):d/f;for(var t in g)if(g[z](t)){switch(Ea[t]){case "along":k=r*f*h[t];i.back&&(k=i.len-k);e=za(i[t],k);n.translate(h.sx-h.x||0,h.sy-h.y||0);h.x=e.x;h.y=e.y;n.translate(e.x-h.sx,e.y-h.sy);i.rot&&n.rotate(h.r+e.alpha,e.x,e.y);break;case O:k=+g[t]+r*f*h[t];break;case "colour":k="rgb("+[Ja(F(g[t].r+r*f*h[t].r)),Ja(F(g[t].g+r*f*h[t].g)),Ja(F(g[t].b+r*f*h[t].b))][Q](",")+")";break;case "path":k=[];e=0;for(var L=g[t][o];e<L;e++){k[e]=[g[t][e][0]];
for(var B=1,x=g[t][e][o];B<x;B++)k[e][B]=+g[t][e][B]+r*f*h[t][e][B];k[e]=k[e][Q](P)}k=k[Q](P);break;case "csv":switch(t){case "translation":k=h[t][0]*(d-l);e=h[t][1]*(d-l);j.x+=k;j.y+=e;k=k+P+e;break;case "rotation":k=+g[t][0]+r*f*h[t][0];g[t][1]&&(k+=","+g[t][1]+","+g[t][2]);break;case "scale":k=[+g[t][0]+r*f*h[t][0],+g[t][1]+r*f*h[t][1],2 in i[t]?i[t][2]:s,3 in i[t]?i[t][3]:s][Q](P);break;case "clip-rect":k=[];for(e=4;e--;)k[e]=+g[t][e]+r*f*h[t][e];break}break}q[t]=k}n.attr(q);n._run&&n._run.call(n)}else{if(i.along){e=
za(i.along,i.len*!i.back);n.translate(h.sx-(h.x||0)+e.x-h.sx,h.sy-(h.y||0)+e.y-h.sy);i.rot&&n.rotate(h.r+e.alpha,e.x,e.y)}(j.x||j.y)&&n.translate(-j.x,-j.y);i.scale&&(i.scale+=s);n.attr(i);delete S[b];S[o]--;n.in_animation=null;m.is(r,"function")&&r.call(n)}c.prev=d}}m.svg&&n&&n.paper&&n.paper.safari();S[o]&&X.setTimeout(lb)}function Ja(a){return Y($(a,255),0)}function ya(a,b){if(a==null)return{x:this._.tx,y:this._.ty,toString:ib};this._.tx+=+a;this._.ty+=+b;switch(this.type){case "circle":case "ellipse":this.attr({cx:+a+
this.attrs.cx,cy:+b+this.attrs.cy});break;case "rect":case "image":case "text":this.attr({x:+a+this.attrs.x,y:+b+this.attrs.y});break;case "path":var c=Oa(this.attrs.path);c[0][1]+=+a;c[0][2]+=+b;this.attr({path:c});break}return this}u[p].animateWith=function(a,b,c,d,f){S[a.id]&&(b.start=S[a.id].start);return this.animate(b,c,d,f)};u[p].animateAlong=mb();u[p].animateAlongBack=mb(1);function mb(a){return function(b,c,d,f){var e={back:a};m.is(d,"function")?(f=d):(e.rot=d);b&&b.constructor==u&&(b=b.attrs.path);
b&&(e.along=b);return this.animate(e,c,f)}}u[p].onAnimation=function(a){this._run=a||0;return this};u[p].animate=function(a,b,c,d){if(m.is(c,"function")||!c)d=c||null;var f={},e={},g={};for(var h in a)if(a[z](h))if(Ea[z](h)){f[h]=this.attr(h);f[h]==null&&(f[h]=qa[h]);e[h]=a[h];switch(Ea[h]){case "along":var i=kb(a[h]),j=za(a[h],i*!!a.back),l=this.getBBox();g[h]=i/b;g.tx=l.x;g.ty=l.y;g.sx=j.x;g.sy=j.y;e.rot=a.rot;e.back=a.back;e.len=i;a.rot&&(g.r=A(this.rotate())||0);break;case O:g[h]=(e[h]-f[h])/
b;break;case "colour":f[h]=m.getRGB(f[h]);i=m.getRGB(e[h]);g[h]={r:(i.r-f[h].r)/b,g:(i.g-f[h].g)/b,b:(i.b-f[h].b)/b};break;case "path":i=ua(f[h],e[h]);f[h]=i[0];j=i[1];g[h]=[];i=0;for(l=f[h][o];i<l;i++){g[h][i]=[0];for(var n=1,r=f[h][i][o];n<r;n++)g[h][i][n]=(j[i][n]-f[h][i][n])/b}break;case "csv":j=(a[h]+s)[H](V);i=(f[h]+s)[H](V);switch(h){case "translation":f[h]=[0,0];g[h]=[j[0]/b,j[1]/b];break;case "rotation":f[h]=i[1]==j[1]&&i[2]==j[2]?i:[0,j[1],j[2]];g[h]=[(j[0]-f[h][0])/b,0,0];break;case "scale":a[h]=
j;f[h]=(f[h]+s)[H](V);g[h]=[(j[0]-f[h][0])/b,(j[1]-f[h][1])/b,0,0];break;case "clip-rect":f[h]=(f[h]+s)[H](V);g[h]=[];for(i=4;i--;)g[h][i]=(j[i]-f[h][i])/b;break}e[h]=j}}this.stop();this.in_animation=1;S[this.id]={start:a.start||+new Date,ms:b,easing:c,from:f,diff:g,to:e,el:this,callback:d,t:{x:0,y:0}};++S[o]==1&&lb();return this};u[p].stop=function(){S[this.id]&&S[o]--;delete S[this.id];return this};u[p].translate=function(a,b){return this.attr({translation:a+" "+b})};u[p][N]=function(){return"Rapha\u00ebl\u2019s object"};
m.ae=S;function Z(a){this.items=[];this[o]=0;this.type="set";if(a)for(var b=0,c=a[o];b<c;b++)if(a[b]&&(a[b].constructor==u||a[b].constructor==Z)){this[this.items[o]]=this.items[this.items[o]]=a[b];this[o]++}}Z[p][E]=function(){for(var a,b,c=0,d=arguments[o];c<d;c++)if((a=arguments[c])&&(a.constructor==u||a.constructor==Z)){b=this.items[o];this[b]=this.items[b]=a;this[o]++}return this};Z[p].pop=function(){delete this[this[o]--];return this.items.pop()};for(var Ka in u[p])if(u[p][z](Ka))Z[p][Ka]=function(a){return function(){for(var b=
0,c=this.items[o];b<c;b++)this.items[b][a][K](this.items[b],arguments);return this}}(Ka);Z[p].attr=function(a,b){if(a&&m.is(a,U)&&m.is(a[0],"object")){b=0;for(var c=a[o];b<c;b++)this.items[b].attr(a[b])}else{c=0;for(var d=this.items[o];c<d;c++)this.items[c].attr(a,b)}return this};Z[p].animate=function(a,b,c,d){(m.is(c,"function")||!c)&&(d=c||null);var f=this.items[o],e=f,g,h=this,i;d&&(i=function(){!--f&&d.call(h)});c=m.is(c,ea)?c:i;for(g=this.items[--e].animate(a,b,c,i);e--;)this.items[e].animateWith(g,
a,b,c,i);return this};Z[p].insertAfter=function(a){for(var b=this.items[o];b--;)this.items[b].insertAfter(a);return this};Z[p].getBBox=function(){for(var a=[],b=[],c=[],d=[],f=this.items[o];f--;){var e=this.items[f].getBBox();a[E](e.x);b[E](e.y);c[E](e.x+e.width);d[E](e.y+e.height)}a=$[K](0,a);b=$[K](0,b);return{x:a,y:b,width:Y[K](0,c)-a,height:Y[K](0,d)-b}};Z[p].clone=function(a){a=new Z;for(var b=0,c=this.items[o];b<c;b++)a[E](this.items[b].clone());return a};m.registerFont=function(a){if(!a.face)return a;
this.fonts=this.fonts||{};var b={w:a.w,face:{},glyphs:{}},c=a.face["font-family"];for(var d in a.face)if(a.face[z](d))b.face[d]=a.face[d];if(this.fonts[c])this.fonts[c][E](b);else this.fonts[c]=[b];if(!a.svg){b.face["units-per-em"]=da(a.face["units-per-em"],10);for(var f in a.glyphs)if(a.glyphs[z](f)){c=a.glyphs[f];b.glyphs[f]={w:c.w,k:{},d:c.d&&"M"+c.d[I](/[mlcxtrv]/g,function(g){return{l:"L",c:"C",x:"z",t:"m",r:"l",v:"c"}[g]||"M"})+"z"};if(c.k)for(var e in c.k)if(c[z](e))b.glyphs[f].k[e]=c.k[e]}}return a};
G[p].getFont=function(a,b,c,d){d=d||"normal";c=c||"normal";b=+b||{normal:400,bold:700,lighter:300,bolder:800}[b]||400;if(m.fonts){var f=m.fonts[a];if(!f){a=new RegExp("(^|\\s)"+a[I](/[^\w\d\s+!~.:_-]/g,s)+"(\\s|$)","i");for(var e in m.fonts)if(m.fonts[z](e))if(a.test(e)){f=m.fonts[e];break}}var g;if(f){e=0;for(a=f[o];e<a;e++){g=f[e];if(g.face["font-weight"]==b&&(g.face["font-style"]==c||!g.face["font-style"])&&g.face["font-stretch"]==d)break}}return g}};G[p].print=function(a,b,c,d,f,e){e=e||"middle";
var g=this.set(),h=(c+s)[H](s),i=0;m.is(d,c)&&(d=this.getFont(d));if(d){c=(f||16)/d.face["units-per-em"];var j=d.face.bbox.split(V);f=+j[0];e=+j[1]+(e=="baseline"?j[3]-j[1]+ +d.face.descent:(j[3]-j[1])/2);j=0;for(var l=h[o];j<l;j++){var n=j&&d.glyphs[h[j-1]]||{},r=d.glyphs[h[j]];i+=j?(n.w||d.w)+(n.k&&n.k[h[j]]||0):0;r&&r.d&&g[E](this.path(r.d).attr({fill:"#000",stroke:"none",translation:[i,0]}))}g.scale(c,c,f,e).translate(a-f,b-e)}return g};var Jb=/\{(\d+)\}/g;m.format=function(a,b){var c=m.is(b,
U)?[0][M](b):arguments;a&&m.is(a,ea)&&c[o]-1&&(a=a[I](Jb,function(d,f){return c[++f]==null?s:c[f]}));return a||s};m.ninja=function(){La.was?(Raphael=La.is):delete Raphael;return m};m.el=u[p];return m}();
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
