package;


import lime.graphics.cairo.*;
import lime.graphics.opengl.*;
import lime.math.Matrix3;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.RenderEvent;
import openfl.geom.Matrix;
import openfl.utils.Assets;

#if (js && html5)
import js.html.Image;
#end


class Main extends Sprite {
	
	
	private var bitmapData:BitmapData;
	private var cairoMatrix:Matrix3;
	private var cairoPattern:CairoPattern;
	private var cairoSurface:CairoSurface;
	private var glBuffer:GLBuffer;
	private var glMatrixUniform:GLUniformLocation;
	private var glProgram:GLProgram;
	private var glTexture:GLTexture;
	private var glTextureAttribute:Int;
	private var glVertexAttribute:Int;
	
	#if (js && html5)
	private var domImage:Image;
	#end
	
	
	public function new () {
		
		super ();
		
		bitmapData = Assets.getBitmapData ("assets/openfl.png");
		
		addEventListener (RenderEvent.CLEAR_DOM, clearDOM);
		addEventListener (RenderEvent.RENDER_CAIRO, renderCairo);
		addEventListener (RenderEvent.RENDER_CANVAS, renderCanvas);
		addEventListener (RenderEvent.RENDER_DOM, renderDOM);
		addEventListener (RenderEvent.RENDER_OPENGL, renderOpenGL);
		
		x = 100;
		y = 100;
		rotation = 6;
		
	}
	
	
	private function clearDOM (event:RenderEvent):Void {
		
		#if (js && html5)
		event.clearDOMStyle (domImage);
		#end
		
	}
	
	
	private function renderCairo (event:RenderEvent):Void {
		
		if (cairoPattern == null) {
			
			var surface = bitmapData.getSurface ();
			cairoPattern = CairoPattern.createForSurface (surface);
			
			if (event.allowSmoothing) {
				
				cairoPattern.filter = CairoFilter.GOOD;
				
			} else {
				
				cairoPattern.filter = CairoFilter.NEAREST;
				
			}
			
		}
		
		var cairo = event.cairo;
		
		cairo.matrix = event.getCairoMatrix (event.renderTransform);
		cairo.source = cairoPattern;
		cairo.paint ();
		
	}
	
	
	private function renderCanvas (event:RenderEvent):Void {
		
		var context = event.context;
		var transform = event.renderTransform;
		
		context.setTransform (transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty);
		context.drawImage (bitmapData.image.src, 0, 0, bitmapData.width, bitmapData.height);
		
	}
	
	
	private function renderDOM (event:RenderEvent):Void {
		
		#if (js && html5)
		if (domImage == null) {
			
			domImage = new Image ();
			domImage.src = Assets.getPath ("assets/openfl.png");
			
		}
		
		event.applyDOMStyle (domImage);
		#end
		
	}
	
	
	private function renderOpenGL (event:RenderEvent):Void {
		
		var gl:WebGLContext = event.gl;
		
		if (glProgram == null) {
			
			var vertexSource = 
				
				"attribute vec4 aPosition;
				attribute vec2 aTexCoord;
				varying vec2 vTexCoord;
				
				uniform mat4 uMatrix;
				
				void main(void) {
					
					vTexCoord = aTexCoord;
					gl_Position = uMatrix * aPosition;
					
				}";
			
			var fragmentSource = 
				
				#if !desktop
				"precision mediump float;" +
				#end
				"varying vec2 vTexCoord;
				uniform sampler2D uImage0;
				
				void main(void)
				{
					gl_FragColor = texture2D (uImage0, vTexCoord);
				}";
			
			glProgram = GLUtils.createProgram (vertexSource, fragmentSource);
			gl.useProgram (glProgram);
			
			glVertexAttribute = gl.getAttribLocation (glProgram, "aPosition");
			glTextureAttribute = gl.getAttribLocation (glProgram, "aTexCoord");
			glMatrixUniform = gl.getUniformLocation (glProgram, "uMatrix");
			var imageUniform = gl.getUniformLocation (glProgram, "uImage0");
			
			gl.enableVertexAttribArray (glVertexAttribute);
			gl.enableVertexAttribArray (glTextureAttribute);
			gl.uniform1i (imageUniform, 0);
			
			var data = [
				
				bitmapData.width, bitmapData.height, 0, 1, 1,
				0, bitmapData.height, 0, 0, 1,
				bitmapData.width, 0, 0, 1, 0,
				0, 0, 0, 0, 0
				
			];
			
			glBuffer = gl.createBuffer ();
			gl.bindBuffer (gl.ARRAY_BUFFER, glBuffer);
			gl.bufferData (gl.ARRAY_BUFFER, new Float32Array (data), gl.STATIC_DRAW);
			gl.bindBuffer (gl.ARRAY_BUFFER, null);
			
			glTexture = bitmapData.getTexture (cast gl);
			
		} else {
			
			gl.useProgram (glProgram);
			
			gl.enableVertexAttribArray (glVertexAttribute);
			gl.enableVertexAttribArray (glTextureAttribute);
			
		}
		
		var matrix = event.getOpenGLMatrix (event.renderTransform);
		gl.uniformMatrix4fv (glMatrixUniform, false, matrix);
		
		gl.activeTexture (gl.TEXTURE0);
		gl.bindTexture (gl.TEXTURE_2D, glTexture);
		
		#if desktop
		gl.enable (gl.TEXTURE_2D);
		#end
		
		if (event.allowSmoothing) {
			
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
			
		} else {
			
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
			
		}
		
		gl.bindBuffer (gl.ARRAY_BUFFER, glBuffer);
		gl.vertexAttribPointer (glVertexAttribute, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);
		gl.vertexAttribPointer (glTextureAttribute, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
		
		gl.drawArrays (gl.TRIANGLE_STRIP, 0, 4);
		
		gl.bindBuffer (gl.ARRAY_BUFFER, null);
		gl.bindTexture (gl.TEXTURE_2D, null);
		
		#if desktop
		gl.disable (gl.TEXTURE_2D);
		#end
		
		gl.disableVertexAttribArray (glVertexAttribute);
		gl.disableVertexAttribArray (glTextureAttribute);
		gl.useProgram (null);
		
	}
	
	
}