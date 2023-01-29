using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace ToonShading
{
    public class Game1 : Game
    {
        private GraphicsDeviceManager _graphics;
        private SpriteBatch _spriteBatch;

        private KeyboardState currentKS, lastKS;

        private Model currentModel, toyModel, earthModel, asteroidModel;
        private Matrix world, view, projection, invworld;

        private Vector3 eye, target, up;

        private Effect toonEffect;
        private Effect sobelEffect;
        private Effect nullEffect;
        private Effect outlineEffect;
        private Effect diffuseEffect;
        private Effect asteroidEffect;
        private Effect earthEffect;

        private Effect currentPostProcessingEffect;

        RenderTarget2D rt;

        private int degreesY = 0;
        private int degreesX = 0;
        private int degreesZ = 0;

        enum ModelState
        {
            Toy,
            Earth,
            Asteroid
        }

        private ModelState ms = ModelState.Toy;

        public Game1()
        {
            _graphics = new GraphicsDeviceManager(this);
            _graphics.PreferredBackBufferWidth = 1280;
            _graphics.PreferredBackBufferHeight = 720;
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
        }

        protected override void Initialize()
        {
            // TODO: Add your initialization logic here


            rt = new RenderTarget2D(GraphicsDevice,
                GraphicsDevice.PresentationParameters.BackBufferWidth,
                GraphicsDevice.PresentationParameters.BackBufferHeight,
                false,
                GraphicsDevice.PresentationParameters.BackBufferFormat,
                DepthFormat.Depth24);

            world = Matrix.CreateTranslation(new Vector3(0, 0, 0));
            eye = new Vector3(0, 0, 5);
            target = new Vector3(0, 0, 0);
            up = new Vector3(0, 0, 1);
            view = Matrix.CreateLookAt(eye, target, up);
            projection = Matrix.CreatePerspectiveFieldOfView(MathHelper.ToRadians(45), 1280 / 720f, 0.1f, 100f);

            base.Initialize();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            Texture2D whiteTex = new Texture2D(GraphicsDevice, 1, 1);
            whiteTex.SetData(new Color[] { Color.White });

            //

            // Asteroid
            Texture2D asteroidTex = Content.Load<Texture2D>("AsteroidTexture");
            asteroidModel = Content.Load<Model>("LargeAsteroid");
            toonEffect = Content.Load<Effect>("toon");
            toonEffect.Parameters["view"].SetValue(view);
            toonEffect.Parameters["projection"].SetValue(projection);
            toonEffect.Parameters["tex"].SetValue(asteroidTex);

            foreach (ModelMesh m in asteroidModel.Meshes)
            {
                foreach (ModelMeshPart mp in m.MeshParts)
                {
                    mp.Effect = toonEffect;
                }
            }

            // Toy
            toyModel = Content.Load<Model>("sample");
            diffuseEffect = Content.Load<Effect>("diffuse");

            foreach (ModelMesh m in toyModel.Meshes)
            {
                foreach (ModelMeshPart mp in m.MeshParts)
                {
                    mp.Effect = diffuseEffect;
                }
            }

            // Earth
            earthModel = Content.Load<Model>("sphere");
            Texture2D earthsurfaceTexture = Content.Load<Texture2D>("earth_surface");
            Texture2D earthnormalTexture = Content.Load<Texture2D>("earth_normal");
            Texture2D earthlightsTexture = Content.Load<Texture2D>("earth_lights");
            Texture2D earthcloudsTexture = Content.Load<Texture2D>("earth_clouds");
            Texture2D earthoceanTexture = Content.Load<Texture2D>("earth_ocean");
            earthEffect = Content.Load<Effect>("earth");
            earthEffect.Parameters["texSurface"].SetValue(earthsurfaceTexture);
            earthEffect.Parameters["texBump"].SetValue(earthnormalTexture);
            earthEffect.Parameters["texLights"].SetValue(earthlightsTexture);
            earthEffect.Parameters["texClouds"].SetValue(earthcloudsTexture);
            earthEffect.Parameters["texOcean"].SetValue(earthoceanTexture);

            foreach (ModelMesh m in earthModel.Meshes)
            {
                foreach (ModelMeshPart mp in m.MeshParts)
                {
                    mp.Effect = earthEffect;
                }
            }

            // Other effects
            sobelEffect = Content.Load<Effect>("sobel");
            outlineEffect = Content.Load<Effect>("outline");
            //outlineEffect.Parameters["tex"].SetValue(whiteTex);
            outlineEffect.Parameters["eye"].SetValue(eye);

            // Default model to display
            currentModel = earthModel;
            ms = ModelState.Earth;

        }

        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            lastKS = currentKS;

            currentKS = Keyboard.GetState();

            if (currentKS.IsKeyDown(Keys.Left))
                degreesX += 1;
            if (currentKS.IsKeyDown(Keys.Right))
                degreesX -= 1;
            if (currentKS.IsKeyDown(Keys.Up))
                degreesY += 1;
            if (currentKS.IsKeyDown(Keys.Down))
                degreesY -= 1;
            if (currentKS.IsKeyDown(Keys.LeftControl))
                degreesZ -= 1;
            if (currentKS.IsKeyDown(Keys.LeftShift))
                degreesZ += 1;
            if (currentKS.IsKeyDown(Keys.Space))
            {
                if (!lastKS.IsKeyDown(Keys.Space))
                {
                    if (ms == ModelState.Toy)
                    {
                        ms = ModelState.Earth;
                        currentModel = earthModel;
                        currentPostProcessingEffect = null;
                        eye = new Vector3(3.0f, 0, 0);
                        view = Matrix.CreateLookAt(eye, target, up);
                    }
                    else if (ms == ModelState.Earth)
                    {
                        ms = ModelState.Asteroid;
                        currentModel = asteroidModel;
                        currentPostProcessingEffect = sobelEffect;
                        eye = new Vector3(1.5f, 0, 0);
                        view = Matrix.CreateLookAt(eye, target, up);
                    }
                    else
                    {
                        ms = ModelState.Toy;
                        currentModel = toyModel;
                        currentPostProcessingEffect = sobelEffect;
                        
                    }
                }
            }
            if (currentKS.IsKeyDown(Keys.PageUp))
                currentPostProcessingEffect = nullEffect;
            if (currentKS.IsKeyDown(Keys.PageDown))
                currentPostProcessingEffect = sobelEffect;

            

            world = Matrix.CreateRotationY(degreesY / 180.0f) * Matrix.CreateRotationX(degreesX / 180.0f) * Matrix.CreateRotationZ(degreesZ / 180.0f);
            invworld = Matrix.Invert(world);
            toonEffect.Parameters["world"].SetValue(world);
            toonEffect.Parameters["worldInv"].SetValue(invworld);

            outlineEffect.Parameters["world"].SetValue(world);
            outlineEffect.Parameters["viewProj"].SetValue(view * projection);
            outlineEffect.Parameters["eye"].SetValue(eye);
            outlineEffect.Parameters["worldInvTrans"].SetValue(Matrix.Transpose(invworld));

            diffuseEffect.Parameters["WorldMatrix"].SetValue(world);
            diffuseEffect.Parameters["ViewMatrix"].SetValue(view);
            diffuseEffect.Parameters["ProjectionMatrix"].SetValue(projection);
            diffuseEffect.Parameters["WorldInverseTransposeMatrix"].SetValue(Matrix.Transpose(invworld));
            //diffuseEffect.Parameters["EyePosition"].SetValue(eye);

            if (ms == ModelState.Earth)
            {
                earthEffect.Parameters["worldMatrix"].SetValue(world);
                earthEffect.Parameters["viewMatrix"].SetValue(view);
                earthEffect.Parameters["projectionMatrix"].SetValue(projection);
                //earthEffect.Parameters["WorldInverseTranspose"].SetValue(invworld);
                //earthEffect.Parameters["EyePosition"].SetValue(eye);
            }

            base.Update(gameTime);
        }


        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            DrawSceneToTexture();

            _spriteBatch.Begin(SpriteSortMode.Immediate, BlendState.Opaque, SamplerState.LinearWrap, DepthStencilState.Default, RasterizerState.CullNone, currentPostProcessingEffect);

            _spriteBatch.Draw(rt, Vector2.Zero);

            _spriteBatch.End();

            base.Draw(gameTime);
        }

        protected void DrawSceneToTexture()
        {
            // Set the render target
            GraphicsDevice.SetRenderTarget(rt);

            GraphicsDevice.DepthStencilState = new DepthStencilState() { DepthBufferEnable = true };

            // Draw the scene
            GraphicsDevice.Clear(Color.CornflowerBlue);
            foreach (ModelMesh m in currentModel.Meshes)
            {
                Effect e = m.Effects[0];
                //if (ms == ModelState.Earth)
                //    e.Parameters["WorldInverseTranspose"].SetValue(Matrix.Transpose(Matrix.Invert(m.ParentBone.Transform * world)));
                foreach (EffectPass p in e.CurrentTechnique.Passes)
                {
                    p.Apply();
                    
                    m.Draw();
                }
            }

            // Drop the render target
            GraphicsDevice.SetRenderTarget(null);
        }
    }
}
