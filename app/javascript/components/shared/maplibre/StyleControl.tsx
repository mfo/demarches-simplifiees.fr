import { useId, useRef, useEffect } from 'react';
import { Button, Dialog, DialogTrigger, Popover } from 'react-aria-components';

import { Slider } from '../../react-aria/components/Slider';
import { type LayersMap, type MapStyle, NBS } from './styles';

const STYLES = {
  ortho: 'Satellite',
  vector: 'Vectoriel',
  ign: 'Carte IGN'
} as const;

export function StyleSwitch({
  styleId,
  layers,
  setStyle,
  setLayerEnabled,
  setLayerOpacity
}: {
  styleId: MapStyle;
  setStyle: (style: MapStyle) => void;
  layers: LayersMap;
  setLayerEnabled: (layer: string, enabled: boolean) => void;
  setLayerOpacity: (layer: string, opacity: number) => void;
}) {
  const configurableLayers = Object.entries(layers).filter(
    ([, { configurable }]) => configurable
  );
  const mapId = useId();
  const buttonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (buttonRef.current) {
      buttonRef.current.title = 'Sélectionner les couches cartographiques';
    }
  }, []);

  return (
    <DialogTrigger>
      <Button ref={buttonRef}>
        <span
          className="fr-icon-road-map-line fr-icon--sm"
          aria-hidden="true"
        />
      </Button>
      <Popover className="react-aria-popover">
        <Dialog className="fr-modal__body">
          <form
            className="fr-modal__content flex fr-m-4v"
            onSubmit={(event) => event.preventDefault()}
          >
            <div className="fr-fieldset">
              {Object.entries(STYLES).map(([style, title]) => (
                <div className="fr-fieldset__element" key={style}>
                  <div className="fr-radio-group">
                    <input
                      id={`${mapId}-${style}`}
                      value={style}
                      type="radio"
                      name="map-style"
                      defaultValue={style}
                      checked={styleId == style}
                      onChange={(event) => {
                        setStyle(event.target.value as MapStyle);
                      }}
                    />
                    <label htmlFor={`${mapId}-${style}`} className="fr-label">
                      {title.replace(/\s/g, ' ')}
                    </label>
                  </div>
                </div>
              ))}
            </div>
            {configurableLayers.length ? (
              <div className="fr-fieldset__element">
                {configurableLayers.map(
                  ([layer, { enabled, opacity, name }]) => (
                    <div key={layer} className="fr-fieldset__element">
                      <div className="fr-checkbox-group">
                        <input
                          id={`${mapId}-${layer}`}
                          type="checkbox"
                          checked={enabled}
                          onChange={(event) => {
                            setLayerEnabled(layer, event.target.checked);
                          }}
                        />
                        <label
                          className="fr-label"
                          htmlFor={`${mapId}-${layer}`}
                        >
                          {name}
                        </label>
                      </div>
                      <Slider
                        minValue={10}
                        maxValue={100}
                        step={5}
                        value={opacity}
                        onChange={(value) => {
                          setLayerOpacity(layer, value);
                        }}
                        className="react-aria-Slider fr-mt-2v"
                        aria-label={`Réglage de l’opacité de la couche «${NBS}${name}${NBS}»`}
                      />
                    </div>
                  )
                )}
              </div>
            ) : null}
          </form>
        </Dialog>
      </Popover>
    </DialogTrigger>
  );
}
