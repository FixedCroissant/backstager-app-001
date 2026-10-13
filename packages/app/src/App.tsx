import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import { navModule } from './modules/nav';
import { homeModule } from './modules/home';
export default createApp({
  features: [catalogPlugin, navModule, homeModule],
});

// Below is set up to start using Bitbucket authorization in React.
// import { createApp } from '@backstage/frontend-defaults';
// import { createFrontendModule } from '@backstage/frontend-plugin-api';
// import { SignInPageBlueprint } from '@backstage/plugin-app-react';
// import catalogPlugin from '@backstage/plugin-catalog/alpha';
// import { bitbucketAuthApiRef, SignInPageProps } from '@backstage/core-plugin-api';
// import { SignInPage } from '@backstage/core-components';

// import { navModule } from './modules/nav';
// import { homeModule } from './modules/home';

// // 1. Create a Frontend Module that overrides the default SignInPage extension
// const bitbucketSignInModule = createFrontendModule({
//   pluginId: 'app',
//   extensions: [
//     SignInPageBlueprint.make({
//       params: {
//         loader: async () => (props: SignInPageProps) => (
//           <SignInPage
//             {...props}
//             auto
//             provider={{
//               id: 'bitbucket-auth-provider',
//               title: 'Bitbucket',
//               message: 'Sign in using your Bitbucket account',
//               apiRef: bitbucketAuthApiRef,
//             }}
//           />
//         ),
//       },
//     }),
//   ],
// });

// // 2. Pass the module directly into features array
// export default createApp({
//   features: [
//     catalogPlugin,
//     navModule,
//     homeModule,
//     bitbucketSignInModule,
//   ],
// });

//End Area of using the backend area to use Bitbucket Authorization.