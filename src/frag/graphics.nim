import
  logging

import
  opengl,
  sdl2 as sdl

import
  event_bus,
  graphics/color,
  graphics/debug,
  graphics/window

type
  Graphics* = ref object
    rootWindow*: window.Window
    rootGLContext: sdl.GLContextPtr
    debug: debug.Debug
    

proc init*(
  graphics: Graphics,
  rootWindowTitle: string = nil,
  rootWindowPosX, rootWindowPosY: int = window.posUndefined,
  rootWindowWidth = 960, rootWindowHeight = 540,
  rootWindowFlags: uint32 = uint32 window.WindowFlags.Default
): bool =
  if sdl.init(INIT_VIDEO) != SdlSuccess:
    error "Error initializing SDL : " & $getError()
    return false
  
  discard glSetAttribute(SDL_GL_RED_SIZE, 8)
  discard glSetAttribute(SDL_GL_GREEN_SIZE, 8)
  discard glSetAttribute(SDL_GL_BLUE_SIZE, 8)
  discard glSetAttribute(SDL_GL_ALPHA_SIZE, 8)
  discard glSetAttribute(SDL_GL_STENCIL_SIZE, 8)

  discard glSetAttribute(SDL_GL_DEPTH_SIZE, 24)
  discard glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)

  discard glSetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1)
  discard glSetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)

  discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
  discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3)
  discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)
  discard glSetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG or SDL_GL_CONTEXT_DEBUG_FLAG)

  graphics.rootWindow = Window()
  graphics.rootWindow.init(
    rootWindowTitle, 
    rootWindowPosX, rootWindowPosY,
    rootWindowWidth, rootWindowHeight,
    rootWindowFlags
  )

  if graphics.rootWindow.handle.isNil:
    error "Error creating root application window."
    return false
  
  graphics.rootGLContext = glCreateContext(graphics.rootWindow.handle)
  if graphics.rootGLContext.isNil:
    error "Error creating root OpenGL context."
    return false

  if glMakeCurrent(graphics.rootWindow.handle, graphics.rootGLContext) != 0:
    error "Error setting OpenGL context."
    return false

  loadExtensions()

  glViewport(0, 0, GLsizei rootWindowWidth, GLsizei rootWindowHeight)

  return true

proc initializeDebug*(graphics: Graphics, events: EventBus, rootWindowWidth, rootWindowHeight: int) =
  debug "Initializing debug subsystem..."
  graphics.debug = debug.Debug()
  graphics.debug.init(events, rootWindowWidth, rootWindowHeight)
  debug "Debug subsystem initialized."

proc clear*(graphics: Graphics, clearFlags: GLbitfield) =
  glClear(clearFlags)

proc clearColor*(graphics: Graphics, color: color.Color) =
  glClearColor(color.r, color.g, color.b, color.a)  

proc swap*(graphics: Graphics) =
  glSwapWindow(graphics.rootWindow.handle)

proc drawDebugText*(graphics: Graphics, text: string, x, y, scale: float = 1.0, color: color.Color = (r: 1.0, g: 1.0, b: 1.0, a: 1.0)) =
  graphics.debug.drawText(text, x, y, scale, color)

proc shutdown*(graphics: Graphics, events: EventBus) =
  if graphics.rootWindow.isNil:
    return
  elif graphics.rootWindow.handle.isNil:
    debug "Shutting down SDL..."
    sdl.quit()
    debug "SDL shut down."
  else:
    debug "Destroying root window and shutting down SDL..."
    sdl.destroyWindow(graphics.rootWindow.handle)
    sdl.quit()
    debug "SDL shut down."

  if not graphics.debug.isNil:
    debug "Shutting down debug subsystem..."
    graphics.debug.shutdown(events)
    debug "Debug subsystem shut down."